class Random_Sequence extends uvm_sequence #(Adder_sequence_item);
    //1. an Object
    `uvm_object_utils(Random_Sequence)
    

    //3. Constructor
    function new(string name = "Random_Sequence");
        super.new(name);
    endfunction: new

    //4. Task body
    task body();

        repeat(5) begin
        Adder_sequence_item transaction = Adder_sequence_item::type_id::create("transaction");

        transaction.randomize() with {reset == 0; valid == 1;};
    
        start_item(transaction);
            `uvm_info(get_type_name(), $sformatf("Random_Sequence:  \n %s", transaction.sprint()),UVM_NONE)
        finish_item(transaction);
    
        end 
     
    endtask: body
endclass: Random_Sequence
