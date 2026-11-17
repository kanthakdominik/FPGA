// Model rejestrów (RAL) bloku axil_regs: klasy rejestrów z polami i dostępem, blok z mapą adresów
// oraz adapter tłumaczący operacje modelu na transakcje agenta AXI4-Lite.
package regs_ral_pkg;
    import uvm_pkg::*;
    import axil_pkg::*;
    `include "uvm_macros.svh"

    class reg_id extends uvm_reg;
        `uvm_object_utils(reg_id)
        rand uvm_reg_field id;
        function new(string name = "reg_id");
            super.new(name, 32, UVM_NO_COVERAGE);
        endfunction
        virtual function void build();
            id = uvm_reg_field::type_id::create("id");
            //        rodzic, szer., lsb, dostęp, volatile, reset,         ma reset, rand, osobny dostęp
            id.configure(this, 32, 0, "RO", 0, 32'h414C_5531, 1, 0, 1);
        endfunction
    endclass

    class reg_ctrl extends uvm_reg;
        `uvm_object_utils(reg_ctrl)
        rand uvm_reg_field op;
        rand uvm_reg_field irq_en;
        function new(string name = "reg_ctrl");
            super.new(name, 32, UVM_NO_COVERAGE);
        endfunction
        virtual function void build();
            op     = uvm_reg_field::type_id::create("op");
            irq_en = uvm_reg_field::type_id::create("irq_en");
            op.configure(this, 3, 0, "RW", 0, 3'd0, 1, 1, 0);
            irq_en.configure(this, 1, 8, "RW", 0, 1'b0, 1, 1, 0);
        endfunction
    endclass

    // OPA i OPB: 8 bitów danych w młodszym bajcie
    class reg_operand extends uvm_reg;
        `uvm_object_utils(reg_operand)
        rand uvm_reg_field value;
        function new(string name = "reg_operand");
            super.new(name, 32, UVM_NO_COVERAGE);
        endfunction
        virtual function void build();
            value = uvm_reg_field::type_id::create("value");
            value.configure(this, 8, 0, "RW", 0, 8'd0, 1, 1, 1);
        endfunction
    endclass

    // RESULT: tylko odczyt, wartość zależy od innych rejestrów — pola „volatile”
    class reg_result extends uvm_reg;
        `uvm_object_utils(reg_result)
        uvm_reg_field res, carry, zero, err;
        function new(string name = "reg_result");
            super.new(name, 32, UVM_NO_COVERAGE);
        endfunction
        virtual function void build();
            res   = uvm_reg_field::type_id::create("res");
            carry = uvm_reg_field::type_id::create("carry");
            zero  = uvm_reg_field::type_id::create("zero");
            err   = uvm_reg_field::type_id::create("err");
            res.configure(this, 8, 0, "RO", 1, 8'd0, 1, 0, 0);
            carry.configure(this, 1, 8, "RO", 1, 1'b0, 1, 0, 0);
            zero.configure(this, 1, 9, "RO", 1, 1'b1, 1, 0, 0);     // po resecie 0 + 0 = 0
            err.configure(this, 1, 10, "RO", 1, 1'b0, 1, 0, 0);
            // pola volatile domyślnie nie są porównywane przez mirror(UVM_CHECK); test przewiduje ich
            // wartość (predict) przed sprawdzeniem, więc porównanie włączamy
            res.set_compare(UVM_CHECK);
            carry.set_compare(UVM_CHECK);
            zero.set_compare(UVM_CHECK);
            err.set_compare(UVM_CHECK);
        endfunction
    endclass

    // STATUS: ERR ustawiany przez układ (zapis CTRL z OP = 7), kasowany zapisem 1 — W1C, volatile
    class reg_status extends uvm_reg;
        `uvm_object_utils(reg_status)
        uvm_reg_field err;
        function new(string name = "reg_status");
            super.new(name, 32, UVM_NO_COVERAGE);
        endfunction
        virtual function void build();
            err = uvm_reg_field::type_id::create("err");
            err.configure(this, 1, 0, "W1C", 1, 1'b0, 1, 0, 1);
            err.set_compare(UVM_CHECK);
        endfunction
    endclass

    class reg_scratch extends uvm_reg;
        `uvm_object_utils(reg_scratch)
        rand uvm_reg_field value;
        function new(string name = "reg_scratch");
            super.new(name, 32, UVM_NO_COVERAGE);
        endfunction
        virtual function void build();
            value = uvm_reg_field::type_id::create("value");
            value.configure(this, 32, 0, "RW", 0, 32'd0, 1, 1, 1);
        endfunction
    endclass

    class regs_block extends uvm_reg_block;
        `uvm_object_utils(regs_block)
        rand reg_id      id;
        rand reg_ctrl    ctrl;
        rand reg_operand opa, opb;
        reg_result       result;
        reg_status       status;
        rand reg_scratch scratch;

        function new(string name = "regs_block");
            super.new(name, UVM_NO_COVERAGE);
        endfunction

        virtual function void build();
            id      = reg_id::type_id::create("id");
            ctrl    = reg_ctrl::type_id::create("ctrl");
            opa     = reg_operand::type_id::create("opa");
            opb     = reg_operand::type_id::create("opb");
            result  = reg_result::type_id::create("result");
            status  = reg_status::type_id::create("status");
            scratch = reg_scratch::type_id::create("scratch");
            id.configure(this);      id.build();
            ctrl.configure(this);    ctrl.build();
            opa.configure(this);     opa.build();
            opb.configure(this);     opb.build();
            result.configure(this);  result.build();
            status.configure(this);  status.build();
            scratch.configure(this); scratch.build();

            //                       nazwa,  adres bazowy, bajtów na słowo, kolejność bajtów
            default_map = create_map("map", 'h0, 4, UVM_LITTLE_ENDIAN);
            default_map.add_reg(id,      'h00, "RO");
            default_map.add_reg(ctrl,    'h04, "RW");
            default_map.add_reg(opa,     'h08, "RW");
            default_map.add_reg(opb,     'h0C, "RW");
            default_map.add_reg(result,  'h10, "RO");
            default_map.add_reg(status,  'h14, "RW");
            default_map.add_reg(scratch, 'h18, "RW");

            // rejestrów z efektami ubocznymi nie sprawdza test bit-bash
            uvm_resource_db #(bit)::set({"REG::", status.get_full_name()}, "NO_REG_BIT_BASH_TEST", 1, this);
            uvm_resource_db #(bit)::set({"REG::", result.get_full_name()}, "NO_REG_BIT_BASH_TEST", 1, this);
            lock_model();
        endfunction
    endclass

    // adapter: operacja modelu rejestrów <-> transakcja agenta AXI4-Lite
    class axil_reg_adapter extends uvm_reg_adapter;
        `uvm_object_utils(axil_reg_adapter)

        function new(string name = "axil_reg_adapter");
            super.new(name);
            supports_byte_enable = 1;
            provides_responses   = 0;
        endfunction

        virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
            axil_item t = axil_item::type_id::create("t");
            if (!t.randomize())                          // losowe opóźnienia; pola operacji poniżej
                `uvm_fatal("ADAPTER", "randomize() nie powiodlo sie")
            t.dir  = (rw.kind == UVM_WRITE) ? AXIL_WRITE : AXIL_READ;
            t.addr = rw.addr[4:0];
            t.data = rw.data[31:0];
            t.strb = (rw.kind == UVM_WRITE) ? rw.byte_en[3:0] : 4'h0;
            return t;
        endfunction

        virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
            axil_item t;
            if (!$cast(t, bus_item)) `uvm_fatal("ADAPTER", "zly typ transakcji")
            rw.kind    = (t.dir == AXIL_WRITE) ? UVM_WRITE : UVM_READ;
            rw.addr    = t.addr;
            rw.data    = t.data;
            rw.byte_en = t.strb;
            rw.status  = (t.resp == 2'b00) ? UVM_IS_OK : UVM_NOT_OK;
        endfunction
    endclass
endpackage
