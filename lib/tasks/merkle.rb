require 'mongoid'
require 'digest'
require 'base64'

class MerkleTree

  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :merkle_tree_nodes
  belongs_to :blockchain, optional: true, :index => true

  field :root_node_id

  def traverse_tree(subtree = nil)
    return if subtree.nil?
    #visit current_node
    return if subtree.children.nil?
    puts subtree.inspect
    nsubtree_left  = subtree.children.first
    nsubtree_right = subtree.children.last
    traverse_tree( nsubtree_left )
    traverse_tree( nsubtree_right )
  end

  def get_leaf_height
    leaf = MerkleTreeNode.where(:merkle_tree_id => self.id, :node_type => MerkleTreeNode::LEAF).first
    leaf_height = 1
    parent = leaf.parent
    while not parent.nil?
      leaf_height = leaf_height + 1
      parent = parent.parent
    end
    return leaf_height
  end

  def add_leaf(params)
    #recently_added_leaves = MerkleTreeNode.where(:node_type => 'leaf').order(:created_at => :desc).limit(2) 
    new_leaf = MerkleTreeNode.new(:merkle_tree => self, :node_type => MerkleTreeNode::LEAF, :stored_data => params[:stored_data])
    available_parent = available_parent(new_leaf)
    new_leaf.save
    update_digests_for_recent_leaf(new_leaf)
    return new_leaf
    #@logger.debug "new leaf added " + new_leaf.inspect
    #@logger.debug "available parent " + available_parent.inspect
  end

  def available_parent(new_node)
    recently_added_leaf = MerkleTreeNode.where(:merkle_tree => self, :node_type => MerkleTreeNode::LEAF).order(:created_at => :desc).limit(1).first
    if recently_added_leaf.nil? #if there are no leaves, we still need a root to add the leaf
      #make root
      new_root = MerkleTreeNode.new(:merkle_tree_id => self.id, :node_type => MerkleTreeNode::ROOT )
      new_root.save
      self.root_node_id = new_root.id
      self.save
      new_node.parent = new_root
      new_node.save
      new_root.save
      return new_root
    else #there is a recent leaf that we have
      ral_parent = recently_added_leaf.parent #this shouldn't be nil
      can_add_parent = false
      can_add_parent = (not ral_parent.nil?) 
      can_add_parent_oth = (not ral_parent.children.nil?) if can_add_parent
      if can_add_parent and can_add_parent_oth 
        if recently_added_leaf.parent.children.size == 1
          new_node.parent = recently_added_leaf.parent
          new_node.save
          return recently_added_leaf.parent
        else #recently_added_leaf children is size 2 #last leafs inserted has full parents #need to take care of special cases
          #leaf needs to make  parents based on currentleafheight
          #if root is fulfilled we need to make a new root
          avail_parent_sub(new_node)
        end
      else
        avail_parent_sub(new_node)
      end
    end
  end

  def avail_parent_sub(new_node)
    current_root = MerkleTreeNode.where(:merkle_tree_id => self.id, :node_type => MerkleTreeNode::ROOT).first
    current_root.save if current_root.children.size == 2
    if current_root.fulfilled #thinking we should recursively use this code to iterate until an unfulfilled parent
      #make new root
      current_root.node_type = MerkleTreeNode::PARENT
      new_root = MerkleTreeNode.new(:merkle_tree_id => self.id, :node_type => MerkleTreeNode::ROOT )
      self.root_node_id = new_root.id
      self.save
      new_root.save
      current_root.parent = new_root
      current_root.save
      new_root.save #saving twice to compute merkle root with children available

      new_parent = MerkleTreeNode.new(:merkle_tree_id => self.id, :node_type => MerkleTreeNode::PARENT )
      new_parent.parent = new_root
      new_parent.save

      previous_parent = new_parent
      leaf_height = get_leaf_height
      i = 2
      while i < leaf_height
        new_parent = MerkleTreeNode.new(:merkle_tree_id => self.id, :node_type => MerkleTreeNode::PARENT )
        new_parent.save
        previous_parent.parent = new_parent
        previous_parent.save
        previous_parent = new_parent
        i = i + 1
      end
      if i == leaf_height
          new_node.parent = new_parent
          new_node.save
          new_parent.save #resave to calc child hash
      end
    else #current_root.fulfilled == false
      avail_parent_sub_rec(current_root, 1, new_node, 0) #, new_node?
    end
    return new_node.parent
  end

  #this may need to be changed to start at the root and create parents otherwise we have traverse the tree and add merkle hash's after the leaf is added
  #maybe traverse the tree following unfulfilled nodes, 
  def avail_parent_sub_rec(subtree = nil, current_height = 1, new_node = nil, leaf_height =0)
    return if subtree == nil
    current_parent = subtree
    if leaf_height == 0 or leaf_height.nil?
      leaf_height = get_leaf_height
    end

    parent_children = current_parent.children
    if parent_children.size == 1
      new_parent = MerkleTreeNode.new(:merkle_tree_id => self.id, :node_type => MerkleTreeNode::PARENT )
      new_parent.parent = current_parent
      new_parent.save
      if current_height == leaf_height
        new_node.parent = new_parent
        new_node.save
        new_parent.save #save to cacl merkle for new child
        return new_parent
      end
      avail_parent_sub_rec(new_parent, current_height +1, new_node, leaf_height)
    elsif parent_children.size == 0
      if current_height < leaf_height
        new_parent = MerkleTreeNode.new(:merkle_tree_id => self.id, :node_type => MerkleTreeNode::PARENT )
        new_parent.parent = current_parent
        new_parent.save
        current_parent.save #save to computer merkle for new child
        avail_parent_sub_rec(new_parent, current_height +1, new_node, leaf_height)
      else
        new_node.parent = current_parent
        new_node.save
        current_parent.save #save to cacl merkle for new child
      end
    else #size == 2
      if not parent_children.first.fulfilled
        avail_parent_sub_rec(parent_children.first, current_height, new_node, leaf_height)
      end
      if not parent_children.last.fulfilled
        avail_parent_sub_rec(parent_children.last, current_height, new_node, leaf_height)
      end
    end
  end

  #this is a log n operation
  def update_digests_for_recent_leaf(node)
    return if node.parent.nil?
    parent = node.parent
    parent.save
    update_digests_for_recent_leaf(parent)
  end

end

class MerkleTreeNode

  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :merkle_tree
  #belongs_to :merkle_tree_node

  belongs_to :parent, optional: true, :class_name => 'MerkleTreeNode', :foreign_key => 'parent_id', :index => true
  #has_many :children, :class_name => 'MerkleTreeNode', :primary_key => 'id', :foreign_key => 'parent_id'
  belongs_to :block, optional: true, :index => true


  field :node_type
  field :stored_data
  field :merkle_hash
  field :fulfilled

  before_save :do_digest_fulfillment

  LEAF = "LEAF"  #MerkleTreeNode::LEAF 
  PARENT = "PARENT" #MerkleTreeNode::PARENT
  ROOT = "ROOT" #MerkleTreeNode::ROOT

  def do_digest_fulfillment
    return if self.fulfilled
    case self.node_type
      when MerkleTreeNode::LEAF
        self.merkle_hash = Base64.encode64(Digest::SHA256.digest(self.stored_data))
        self.fulfilled = true
      when MerkleTreeNode::PARENT, MerkleTreeNode::ROOT
        children = self.children
        if children.size == 2
          dec_fc = Base64.decode64(children.last.merkle_hash.to_s) 
          dec_sc = Base64.decode64(children.first.merkle_hash.to_s)
          self.merkle_hash = Base64.encode64(Digest::SHA256.digest(dec_fc + " " + dec_sc))
          self[:fulfilled] = true
          @fulfilled = true
          self.fulfilled = true
        elsif children.size == 1
          unless children.first.merkle_hash.nil?
            dec_fc = Base64.decode64(children.first.merkle_hash) 
            self.merkle_hash = Base64.encode64(Digest::SHA256.digest(dec_fc + " " + dec_fc))
            self.fulfilled = false
          end
        else #parent of no one do nothing
      end
    end
  end

  #right child is most recently made
  #left child is the older of the siblings
  def children
    MerkleTreeNode.all.where(:parent_id => self.id).order(:created_at => :desc)
  end

  def sibling(node = self)
    return if node.nil?
    common_parent = node.parent
    return if common_parent.nil?
    parent_children = common_parent.children
    return if parent_children.nil?
    for n in parent_children
      if n.id != node.id
        return n
      end
    end
  end
end
