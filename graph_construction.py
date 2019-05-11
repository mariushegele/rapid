clause = []

if clause.type == fact

node entry_node = new Node('E')
node return_ = new Node('R')

connect(entry_node, return_, 1)




if clause.type == rule


c = 0
for subgoal in clause:


    # Construct E and Distribute to Subgoals

    node entry_node = new Node('E')
    node copy_node = new Node('C')
    node update_node = new Node('U')

    entry_node.right_out = copy_node
    copy_node.next_out = update_node
    update_node.right_input = subgoal.id

    """ optional
    if(c > 0) {
        node copy_node = new Node('C')
        entry_node.right_out = copy_node
        copy_node.next_out = update_node
    } else {
        entry_node.right_out = update_node
    }
    """

    if(c > 0):
        # Check Variables dependencies and construct Subgraphs

        for previous_subgoal in previous_subgoals:
            shared = sharedVariables(subgoal, previous_subgoal)
            this_in_head = sharedVariables(clause.head, subgoal)
            prev_in_head = sharedVariables(clause.head, previous_subgoal)

            # 1. unconditional (in)dependence?
            # 2. ground test?
            #     + independence test?
            # 4. independence test.

            if(this_in_head == 0):
                if shared > 0:
                    # unconditional dependency
                else:   # shared = 0
                    # unconditional independency

            else: # this_in_head > 0
                ground_test_vars = [x if x in this_in_head for x in shared]

                this_diff = [ x if x not in shared for x in this_in_head ] # all not shared in head
                prev_diff = [ y if y not in shared for y in prev_in_head ] # all prev. not shared in head

                # ind_test_vars = [ (x,y) for x in this_diff for y in prev_diff ] # all permutations of uniques 
                ind_test_vars = [ this_diff, prev_diff ]

                if ground_test_vars > 0:
                    # G node with ground_test_vars as input

                
                    if ind_test_vars > 0:
                        # additional I node with ind_test_vars as input


                else if ind_test_vars > 0:
                    # I node only
                
                else:
                    # unexpected behaviour




        for variable in subgoal:
            variable.in_head = contains(clause.head, variable)
            # false -> local variable -> unconditional (in)dependency
            # true  -> common variable or check for independece
            
            for previous_subgoal in previous_subgoals:
                if(contains(previous_subgoal, variable)):
                    variable.contained_in.push(subgoal)

            # !in_head & contained_in > 0 -> temp variable -> unconditional dependency (a)
            if ( not in_head and contained_in.len > 0 ):
                dependent_vars.push(var)

                # always update

                update_node = new Node('U')
                update.right_in = env_distr.left_out
                update.left_in = previous_subgoal.apply_distr
                update.left_out = apply

            # !in_head & contained_in = 0 -> unconditional independency (e)
            else if (not in head and contained_len = 0 ):
                ## nothing necessary

            # in_head  & contained_in > 0 -> common variable -> ground test (b)
            else if ( in_head and contained_in.len > 0 ):
                ground_tests.push(var)
                # with which subgoals?
                #   any preceding subgoal that also contained this variable
                prev_ground = None

                for subgoal in var.contained_in:
                    ground_node = new Node('G')
                    ground_node.input = var.id
                    if(prev_ground == None):
                        env_distr.left_out = ground_node # env distr.
                    else:
                        prev_ground.left_out = ground_node
                        prev_ground_upd.left_out = ground_node

                    update_node = new Node('U')
                    subgoal.current_out = update_node.left_in # if current_out used copy node
                    ground_node.left_out = update.right_in
                    
                    # merge ground_node.right_out with update.left_out
                    ground_node.right_out = # next_ground or apply
                    update_node.left_out =       # next_ground or apply

                    prev_ground = ground_node
                    prev_ground_upd = update_node
                    


            # in_head  & contained_in = 0 -> possibly independent? (d)
            else if ( in_head and contained_in.len = 0 ):
                independence_tests.push(var)
                # with what other variable?
                #   non_common in previous subgoal

                for head_variable in head:
                    if(variable == head_variable) continue # jump itself
                    else if previous_subgoals.contain(head_variable) and # exception see paper:
                        # check with this variable
                        ind_node = new Node('I')
                        ind_node.input = [[variable.id, head_variable.id]]

                        ground.right_out = ind_node # if a variable had to be ground checked
                        env_distr.left_out = ind_node # if only this variable exists

                        update_node = new Node('U')
                        ind_node.left_out = update_node # not independent
                        ind_node.right_out = apply_node


                    else:
                        # could not have been bound yet
        
            else:
                # shouldn't happen

    # finished dependency tests

    # then apply and return
    node apply = new Node('A')
    node update = new Node('U')

    env_return.left_out = update.right_in

    # when there are more than one subgoal a copy is necessary
    if(subgoal != clause.first_subgoal) {
        node copy = new Node('C')
        apply.left_out = copy

        copy.out = update.left_in
        apply_distr = copy
    } else {
        apply.left_out = update.left_in
        apply_distr = copy
    }

    # return
    node return_node = new Node('R')
    update.left_out = return_node

    c+= 1