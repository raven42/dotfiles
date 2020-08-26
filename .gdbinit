set solib-absolute-prefix oss

python
sys.path.insert(0, '/home/dh404494/bin')
import offsets
end

set height 0
set width 0

set pagination off

define printmem
	if $argc == 0
		set $t = (RBTREE *)mtracer.tree
		print $t
		print *$t
	end
	if $argc != 1
		echo "Please specify only RBNODE pointer value"
		return
	end
	if $argc == 1
		set $n = (RBNODE*)$arg0
		set $m = (esm_mem_entry_t*)$n->data
		printf "0x%x = {p:0x%x l:0x%x r:0x%x k:0x%x c:%d d:0x%x} %s:%d size:%d\n", $n, $n->parent, $n->left, $n->right, $n->key, $n->color, $n->data, $m->file, $m->line, $m->size
	end
end

define printnode
	if $argc == 1
		set $n = (RBNODE*)$arg0
		printf "0x%x = {p:0x%x l:0x%x r:0x%x k:0x%x c:%d d:0x%x}\n", $n, $n->parent, $n->left, $n->right, $n->key, $n->color, $n->data
	end
end

define mem_tree_walk
	set $node_$arg0 = (RBNODE*)($arg1)
	set $nil = ($arg2)
	set $branch_$arg0 = ($arg3)
	set $leftid_$arg0 = $arg0 + 1
	set $rightid_$arg0 = $arg0 + 2

	if $node_$arg0->left != $nil
		mem_tree_walk $leftid_$arg0 $node_$arg0->left $nil 0
	end
	printmem $node_$arg0
	if $node_$arg0->right != $nil
		mem_tree_walk $rightid_$arg0 $node_$arg0->right $nil 1
	end
end
document mem_tree_walk
	NODE-ID NODE NIL BRANCH
	Recursively walk the binary tree printing out each node ignoring branches where NODE is equal to NIL
end

define printmem_tree
	set $tree = (RBTREE *)mtracer.tree
	mem_tree_walk 0 $tree->root $tree->nil 3 1
end
document printmem_tree
	Recursively walk the binary tree printing out each node
end

define tree_walk
	set $node_$arg0 = (RBNODE*)($arg1)
	set $nil = ($arg2)
	set $branch_$arg0 = ($arg3)
	set $leftid_$arg0 = $arg0 + 1
	set $rightid_$arg0 = $arg0 + 2

	if $node_$arg0->left != $nil
		tree_walk $leftid_$arg0 $node_$arg0->left $nil 0
	end
	printnode $node_$arg0
	if $node_$arg0->right != $nil
		tree_walk $rightid_$arg0 $node_$arg0->right $nil 1
	end
end
document tree_walk
	NODE-ID NODE NIL BRANCH
	Recursively walk the binary tree printing out each node ignoring branches where NODE is equal to NIL
end

define printtree
	set $tree = (RBTREE *)$arg0
	tree_walk 0 $tree->root $tree->nil 3 1
end
document printtree
	RBTREE
	Print each node of the RBTREE
end
