// Transakcja ALU i model referencyjny — wspólne dla testbenchy modułu 10 (10.01–10.05).
// alu_txn       — operacja (op, a, b) i odpowiedź (res, carry, zero, err); losowanie tylko legalnych kodów
// alu_txn_edge  — operandy z wartości brzegowych (dziedziczenie + dodatkowe ograniczenie)
// alu_txn_bad   — kod niedozwolony (nadpisanie ograniczenia c_legal o tej samej nazwie)
package alu_txn_pkg;
    localparam int W = 8;
    typedef logic [W-1:0] data_t;
    typedef enum logic [2:0] {OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_SHL, OP_SHR, OP_BAD} op_e;

    class alu_txn;
        static int unsigned n_created = 0;     // wspólny dla wszystkich obiektów klasy
        int unsigned        id;
        rand op_e           op;
        rand data_t         a, b;
        data_t              res;               // odpowiedź: z modelu (predict) albo z monitora
        bit                 carry, zero, err;

        constraint c_legal { op != OP_BAD; }

        function new();
            id = n_created++;
        endfunction

        static function void reset_count();
            n_created = 0;
        endfunction

        virtual function string kind();
            return "txn";
        endfunction

        virtual function string convert2string();
            return $sformatf("%s #%0d %s a=%0d b=%0d -> res=%0d c=%b z=%b e=%b",
                             kind(), id, op.name(), a, b, res, carry, zero, err);
        endfunction

        // kopiowanie pól (bez id — każdy obiekt ma własny numer)
        virtual function void copy(alu_txn rhs);
            op    = rhs.op;
            a     = rhs.a;
            b     = rhs.b;
            res   = rhs.res;
            carry = rhs.carry;
            zero  = rhs.zero;
            err   = rhs.err;
        endfunction

        virtual function alu_txn clone();
            alu_txn t = new();
            t.copy(this);
            return t;
        endfunction

        function bit same_result(alu_txn rhs);
            return res == rhs.res && carry == rhs.carry && zero == rhs.zero && err == rhs.err;
        endfunction

        // model referencyjny: liczby całkowite, niezależnie od kodu układu
        function void predict();
            int x = int'(a), y = int'(b), m = 1 << W, r = 0, sh = int'(b) % W;
            carry = 1'b0;
            err   = 1'b0;
            case (op)
                OP_ADD: begin r = (x + y) % m; carry = (x + y >= m); end
                OP_SUB: begin r = (x - y + m) % m; carry = (x < y); end
                OP_AND: r = x & y;
                OP_OR:  r = x | y;
                OP_XOR: r = x ^ y;
                OP_SHL: r = (x * (1 << sh)) % m;
                OP_SHR: r = x / (1 << sh);
                default: err = 1'b1;
            endcase
            res  = data_t'(r);
            zero = (r == 0);
        endfunction
    endclass

    class alu_txn_edge extends alu_txn;
        constraint c_edge {
            a inside {8'h00, 8'h01, 8'h7F, 8'h80, 8'hFE, 8'hFF};
            b inside {8'h00, 8'h01, 8'h7F, 8'h80, 8'hFE, 8'hFF};
        }

        virtual function string kind();
            return "edge";
        endfunction

        virtual function alu_txn clone();
            alu_txn_edge t = new();
            t.copy(this);
            return t;
        endfunction
    endclass

    class alu_txn_bad extends alu_txn;
        constraint c_legal { op == OP_BAD; }   // ta sama nazwa: zastępuje ograniczenie klasy bazowej

        virtual function string kind();
            return "bad";
        endfunction
    endclass
endpackage
