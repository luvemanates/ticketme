require 'mongoid'
require 'digest'
require 'base64'
require_relative 'blockchain'

class MerkleTree

  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessor :logger, :leaf_inserted

  has_many :merkle_tree_nodes
  belongs_to :blockchain, optional: true, :index => true

  field :root_node_id

  before_save :pre_init

  def pre_init
    @logger = Logger.new(Logger::DEBUG)
  end

  def visit(subtree, new_leaf, leaf_height, current_height, leaf_inserted)
    return if subtree.fulfilled or leaf_inserted #this line is finished
    case subtree.node_type
      when MerkleTreeNode::LEAF
        return leaf_inserted
      when MerkleTreeNode::PARENT
        leaf_inserted = insert_for_parent(subtree, new_leaf, leaf_height, current_height, leaf_inserted)
        return leaf_inserted
      when MerkleTreeNode::ROOT
        leaf_inserted = insert_for_root(subtree, new_leaf, leaf_height, current_height, leaf_inserted)
        return leaf_inserted
    end
  end

  def traverse_tree(subtree = nil, new_leaf = nil, leaf_height, current_height, leaf_inserted )
    @logger = Logger.new(Logger::DEBUG) if @logger.nil?
    #@logger.debug 'subtree.nil? ' + subtree.nil?.to_s
    return if subtree.nil?
    #@logger.debug 'subtree.fulfilled ' + subtree.fulfilled.to_s
    #@logger.debug 'leaf_inserted ' + leaf_inserted.to_s
    #@logger.debug 'subtree is again ' + subtree.inspect
    return if subtree.fulfilled or @leaf_inserted
    #visit current_node
    @leaf_inserted = visit(subtree, new_leaf, leaf_height, current_height, @leaf_inserted )
    return if subtree.children.nil?
    #puts subtree.inspect
    nsubtree_left  = subtree.children.first
    nsubtree_right = subtree.children.last
    if (not nsubtree_left.fulfilled) and (not nsubtree_left.nil?) and (not @leaf_inserted)
      #@logger.debug 'traverse_tree( current_root, new_leaf, leaf_height=' + leaf_height.to_s + ', current_height=' + (current_height + 1).to_s + ', leaf_inserted=' + leaf_inserted.to_s + ')'
      traverse_tree( nsubtree_left, new_leaf, leaf_height, current_height + 1, @leaf_inserted )
    end
    if (not nsubtree_right.fulfilled) and (not nsubtree_right.nil?) and (not @leaf_inserted)
      #@logger.debug 'traverse_tree( current_root, new_leaf, leaf_height=' + leaf_height.to_s + ', current_height=' + (current_height + 1).to_s + ', leaf_inserted=' + leaf_inserted.to_s + ')'
      traverse_tree( nsubtree_right, new_leaf, leaf_height, current_height + 1, @leaf_inserted )
    end
  end
  
  def insert_for_root(subtree, new_leaf, leaf_height, current_height, leaf_inserted )
    if subtree.children.size == 2
      #if two leaves or two parents
      if subtree.fulfilled #root is fulfilled so we need to create a new one
        new_root = MerkleTreeNode.new(:merkle_tree_id => self.id, :node_type => "ROOT", :fulfilled => false)
        new_root.save
        self.root_node_id = new_root.id
        old_root = subtree
        old_root.node_type = "PARENT"
        old_root.parent = new_root
        old_root.save
        return @leaf_inserted
      end
      #otherwise its just filled so just return
      return leaf_inserted
    elsif subtree.children.size == 1
      #if one leave or one parents
      if subtree.children.first.node_type == "PARENT"
        new_node = MerkleTreeNode.new(:merkle_tree_id => self.id, :node_type => "PARENT", :parent_id => subtree.id, :fulfilled => false)
        new_node.save
        return @leaf_inserted
      elsif subtree.children.first.node_type == "LEAF"
        new_leaf.parent = subtree
        new_leaf.save
        @leaf_inserted = true
        return @leaf_inserted
      end
    elsif subtree.children.size == 0
      #if no leaf or parents at root
      #insert a leaf. if at the right height
      if leaf_height == (current_height + 1)
        new_leaf.parent = subtree
        new_leaf.save
        @leaf_inserted = true
        return @leaf_inserted
      else
        #insert parent
        new_node = MerkleTreeNode.new(:merkle_tree_id => self.id, :node_type => "PARENT", :parent_id => subtree.id, :fulfilled => false)
        new_node.save
        return @leaf_inserted
      end
    end
  end

  def insert_for_parent(subtree, new_leaf, leaf_height, current_height, leaf_inserted)
    if subtree.children.size == 2
      #if two leaves or two parents
      #two leaves -- this node is filled so return
      return leaf_inserted
    elsif subtree.children.size == 1
      #if one leave or parent
      #one leaf
      if subtree.children.first.node_type == "LEAF"
        new_leaf.parent = subtree
        new_leaf.save
        @leaf_inserted = true
        return @leaf_inserted
      elsif subtree.children.first.node_type == "PARENT"
        #@logger.debug( "returning in weird edge case") if leaf_height == (current_height + 1)
        return( leaf_inserted ) if leaf_height == (current_height + 1)
        new_parent = MerkleTreeNode.new(:merkle_tree_id => self.id, :node_type => "PARENT", :parent_id => subtree.id, :fulfilled => false)
        new_parent.save
        return @leaf_inserted
      end
    elsif subtree.children.size == 0
      #if no leaves or parents
      #if we are at the right height add leaf
      if leaf_height == (current_height + 1)
        #@logger.debug "!!!!!!!!!!!!!!!!!!!!!!!"
        #@logger.debug "Should be creating a leaf with a save here"
        #@logger.debug "!!!!!!!!!!!!!!!!!!!!!!!"
        new_leaf.parent = subtree
        new_leaf.save
        @leaf_inserted = true
        #@logger.debug new_leaf.inspect
        return @leaf_inserted
      else #
        new_parent = MerkleTreeNode.new(:merkle_tree_id => self.id, :node_type => "PARENT", :parent_id => subtree.id, :fulfilled => false)
        new_parent.save
        #leaf_inserted = true
        return @leaf_inserted
      end
    end
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

  def inspect_tree(subtree)
    return if subtree.nil?
    @logger.debug subtree.inspect
    nsubtree_left  = subtree.children.first
    nsubtree_right = subtree.children.last
    inspect_tree( nsubtree_left )
    inspect_tree( nsubtree_right)
  end

  def add_leaf(params)
    @leaf_inserted = false
    #recently_added_leaves = MerkleTreeNode.where(:node_type => 'leaf').order(:created_at => :desc).limit(2) 
    new_leaf = MerkleTreeNode.new(:merkle_tree_id => self.id, :block_id => params[:block_id], :node_type => MerkleTreeNode::LEAF, :stored_data => params[:stored_data], :fulfilled => false)

    recently_added_leaf = MerkleTreeNode.where(:node_type => MerkleTreeNode::LEAF, :merkle_tree_id => self.id).order(:created_at => :desc).first 

    #case 1 - no nodes
    if self.merkle_tree_nodes.empty?
      new_root = MerkleTreeNode.new(:node_type => MerkleTreeNode::ROOT, :merkle_tree_id => self.id, :fulfilled => false)
      new_root.save
      self.root_node_id = new_root.id
      new_leaf.parent = new_root
      new_leaf.save
      @leaf_inserted = true
    #case 2 recently added has space available -- easiest insert case
    elsif recently_added_leaf
      if recently_added_leaf.parent.children.size == 1
        new_leaf.parent = recently_added_leaf.parent
        new_leaf.save
        update_digests_for_recent_leaf(new_leaf)
        @leaf_inserted = true
      end
    end
    if not @leaf_inserted
      current_root = MerkleTreeNode.where(:merkle_tree_id => self.id, :node_type => MerkleTreeNode::ROOT).first
      if current_root.fulfilled
        @logger = Logger.new(Logger::DEBUG) if @logger.nil?
        #@logger.debug "making new root"
        new_root = MerkleTreeNode.new(:merkle_tree_id => self.id, :node_type => MerkleTreeNode::ROOT, :fulfilled => false)
        new_root.save
        #@logger.debug "new_root reload" + new_root.reload.inspect
        current_root.node_type = "PARENT"
        current_root.parent = new_root
        self.root_node_id = new_root.id
        new_root.save #pull in the hash
        current_root = new_root
      end
      leaf_height = get_leaf_height()
      #@logger.debug 'calling traverse tree'
      #@logger.debug 'traverse_tree( current_root, new_leaf, leaf_height=' + leaf_height.to_s + ', current_height=1, leaf_inserted=false)'
      traverse_tree(current_root, new_leaf, leaf_height, 1, @leaf_inserted)
      #new_leaf.save
      update_digests_for_recent_leaf(new_leaf)
    end
    @logger = Logger.new(Logger::DEBUG) if @logger.nil?
    @logger.debug "new leaf added " + new_leaf.inspect
    @logger.debug "new leaf parent " + new_leaf.parent.inspect
    return new_leaf
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
        if base64?(self.stored_data)
          self.merkle_hash = Base64.encode64(Digest::SHA256.digest(self.stored_data))
        else
          self.merkle_hash = Base64.encode64(Digest::SHA256.digest(Base64.encode64(self.stored_data)))
        end
        self.fulfilled = true
      when MerkleTreeNode::PARENT, MerkleTreeNode::ROOT
        children = self.children
        if children.size == 2
          dec_fc = Base64.decode64(children.last.merkle_hash.to_s) 
          dec_sc = Base64.decode64(children.first.merkle_hash.to_s)
          self.merkle_hash = Base64.encode64(Digest::SHA256.digest(dec_fc + " " + dec_sc))
          self.fulfilled = true
        elsif children.size == 1
          unless children.first.merkle_hash.nil?
            dec_fc = Base64.decode64(children.first.merkle_hash) 
            self.merkle_hash = Base64.encode64(Digest::SHA256.digest(dec_fc + " " + dec_fc))
            self.fulfilled = false
          end
        else #parent of no one do nothing
          self.fulfilled = false
        end
    end
  end

  def base64?(value)
    value.is_a?(String) && Base64.strict_encode64(Base64.decode64(value)) == value
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
