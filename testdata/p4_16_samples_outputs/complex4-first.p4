extern E {
    E();
    bit<32> f(in bit<32> x);
}

control c(inout bit<32> r) {
    E() e;
    apply {
        r = e.f(32w4) + e.f(32w5);
    }
}

control simple(inout bit<32> r);
package top(simple e);
top(c()) main;
