struct Version {
    bit<8> major;
    bit<8> minor;
}

error {
    NoError,
    PacketTooShort,
    NoMatch,
    EmptyStack,
    FullStack,
    OverwritingHeader
}

extern packet_in {
    void extract<T>(out T hdr);
    void extract<T>(out T variableSizeHeader, in bit<32> sizeInBits);
    T lookahead<T>();
    void advance(in bit<32> sizeInBits);
    bit<32> length();
}

extern packet_out {
    void emit<T>(in T hdr);
}

match_kind {
    exact,
    ternary,
    lpm
}

match_kind {
    range,
    selector
}

struct standard_metadata_t {
    bit<9>  ingress_port;
    bit<9>  egress_spec;
    bit<9>  egress_port;
    bit<32> clone_spec;
    bit<32> instance_type;
    bit<1>  drop;
    bit<16> recirculate_port;
    bit<32> packet_length;
}

extern Checksum16 {
    bit<16> get<D>(in D data);
}

enum CounterType {
    Packets,
    Bytes,
    Both
}

extern Counter {
    Counter(bit<32> size, CounterType type);
    void increment(in bit<32> index);
}

extern DirectCounter {
    DirectCounter(CounterType type);
}

extern Meter {
    Meter(bit<32> size, CounterType type);
    void meter<T>(in bit<32> index, out T result);
}

extern DirectMeter<T> {
    DirectMeter(CounterType type);
    void read(out T result);
}

extern Register<T> {
    Register(bit<32> size);
    void read(out T result, in bit<32> index);
    void write(in bit<32> index, in T value);
}

extern ActionProfile {
    ActionProfile(bit<32> size);
}

enum HashAlgorithm {
    crc32,
    crc16,
    random,
    identity
}

extern ActionSelector {
    ActionSelector(HashAlgorithm algorithm, bit<32> size, bit<32> outputWidth);
}

parser Parser<H, M>(packet_in b, out H parsedHdr, inout M meta, inout standard_metadata_t standard_metadata);
control VerifyChecksum<H, M>(in H hdr, inout M meta, inout standard_metadata_t standard_metadata);
control Ingress<H, M>(inout H hdr, inout M meta, inout standard_metadata_t standard_metadata);
control Egress<H, M>(inout H hdr, inout M meta, inout standard_metadata_t standard_metadata);
control ComputeCkecksum<H, M>(inout H hdr, inout M meta, inout standard_metadata_t standard_metadata);
control Deparser<H>(packet_out b, in H hdr);
package V1Switch<H, M>(Parser<H, M> p, VerifyChecksum<H, M> vr, Ingress<H, M> ig, Egress<H, M> eg, ComputeCkecksum<H, M> ck, Deparser<H> dep);
header data_h {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
}

header extra_h {
    bit<16> h;
    bit<8>  b1;
    bit<8>  b2;
}

struct packet_t {
    data_h     data;
    extra_h[4] extra;
}

struct Meta {
}

parser p(packet_in b, out packet_t hdrs, inout Meta m, inout standard_metadata_t meta) {
    state start {
        b.extract(hdrs.data);
        transition extra;
    }
    state extra {
        b.extract(hdrs.extra.next);
        transition select(hdrs.extra.last.b2) {
            8w0x80 &&& 8w0x80: extra;
            default: accept;
        }
    }
}

control vrfy(in packet_t h, inout Meta m, inout standard_metadata_t sm) {
    apply {
    }
}

control update(inout packet_t h, inout Meta m, inout standard_metadata_t sm) {
    apply {
    }
}

control ingress(inout packet_t hdrs, inout Meta m, inout standard_metadata_t meta) {
    action setb1(bit<9> port, bit<8> val) {
        hdrs.data.b1 = val;
        meta.egress_spec = port;
    }
    action noop() {
    }
    action setbyte(out bit<8> reg, bit<8> val) {
        reg = val;
    }
    action act1(bit<8> val) {
        hdrs.extra[0].b1 = val;
    }
    action act2(bit<8> val) {
        hdrs.extra[0].b1 = val;
    }
    action act3(bit<8> val) {
        hdrs.extra[0].b1 = val;
    }
    table test1() {
        key = {
            hdrs.data.f1: ternary;
        }
        actions = {
            setb1();
            noop();
        }
        default_action = noop();
    }
    table ex1() {
        key = {
            hdrs.extra[0].h: ternary;
        }
        actions = {
            setbyte(hdrs.extra[0].b1);
            act1();
            act2();
            act3();
            noop();
        }
        default_action = noop();
    }
    table tbl1() {
        key = {
            hdrs.data.f2: ternary;
        }
        actions = {
            setbyte(hdrs.data.b2);
            noop();
        }
        default_action = noop();
    }
    table tbl2() {
        key = {
            hdrs.data.f2: ternary;
        }
        actions = {
            setbyte(hdrs.extra[1].b1);
            noop();
        }
        default_action = noop();
    }
    table tbl3() {
        key = {
            hdrs.data.f2: ternary;
        }
        actions = {
            setbyte(hdrs.extra[2].b2);
            noop();
        }
        default_action = noop();
    }
    apply {
        test1.apply();
        switch (ex1.apply().action_run) {
            act1: {
                tbl1.apply();
            }
            act2: {
                tbl2.apply();
            }
            act3: {
                tbl3.apply();
            }
        }

    }
}

control egress(inout packet_t hdrs, inout Meta m, inout standard_metadata_t meta) {
    apply {
    }
}

control deparser(packet_out b, in packet_t hdrs) {
    apply {
        b.emit(hdrs.data);
    }
}

V1Switch(p(), vrfy(), ingress(), egress(), update(), deparser()) main;