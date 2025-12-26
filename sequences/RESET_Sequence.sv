class RESET_Sequence extends uvm_sequence #(Adder_sequence_item);
    //1. an Object
    `uvm_object_utils(RESET_Sequence)

    //3. Constructor
    function new(string name = "RESET_Sequence");
        super.new(name);
    endfunction: new

    //4. Task body
    task body();

        Adder_sequence_item transaction = Adder_sequence_item::type_id::create("transaction");
        transaction.randomize() with {reset == 0;};

        start_item(transaction);
            `uvm_info(get_type_name(), $sformatf("Sequence reset:  \n %s", transaction.sprint()),UVM_NONE)
        finish_item(transaction);
    
        transaction.randomize() with {reset == 1;};

        start_item(transaction);
            `uvm_info(get_type_name(), $sformatf("Sequence reset:  \n %s", transaction.sprint()),UVM_NONE)
        finish_item(transaction);
    
     

    endtask: body
 
endclass: RESET_Sequence
