class Adder_Test extends BaseTest;
    // 1. Component
    `uvm_component_utils(Adder_Test)

    RESET_Sequence reset_seq;
    Random_Sequence random_seq;
    string SEQ_NAME;

    // 2. Constructor
    function new(string name = "Adder_Test", uvm_component parent);
        super.new(name, parent);
    endfunction

    // 3. Build Phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        reset_seq = RESET_Sequence::type_id::create("reset_seq");
        random_seq = Random_Sequence::type_id::create("random_seq");
    endfunction

    // 4. Run Phase
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
                    phase.raise_objection(this);
                    $display("\n");
                    reset_seq.start(env.agent.sequencer);
                    phase.drop_objection(this);
        SEQ_NAME ="random_seq";
        case (SEQ_NAME)
                "random_seq": begin
                phase.raise_objection(this);
                $display("\n");
                random_seq.start(env.agent.sequencer);
                phase.drop_objection(this);
                end
        endcase
    endtask
endclass
