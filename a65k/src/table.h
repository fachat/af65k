static operation_t cpu_operations[] = {
{ "BRK", ISA_BASE, false, false, false,NULL,{
    { 0x00, PG_BASE, "imm", ISA_BASE, },
}
},
{ "BPL", ISA_BASE + ISA_CE02, false, false, false,NULL,{
    { 0x10, PG_BASE, "rel", ISA_BASE, },
    { 0x13, PG_BASE, "relw", ISA_CE02, },
}
},
{ "BMI", ISA_BASE + ISA_CE02, false, false, false,NULL,{
    { 0x30, PG_BASE, "rel", ISA_BASE, },
    { 0x33, PG_BASE, "relw", ISA_CE02, },
}
},
{ "BVC", ISA_BASE + ISA_CE02, false, false, false,NULL,{
    { 0x50, PG_BASE, "rel", ISA_BASE, },
    { 0x53, PG_BASE, "relw", ISA_CE02, },
}
},
{ "BVS", ISA_BASE + ISA_CE02, false, false, false,NULL,{
    { 0x70, PG_BASE, "rel", ISA_BASE, },
    { 0x73, PG_BASE, "relw", ISA_CE02, },
}
},
{ "BCC", ISA_BASE + ISA_CE02, false, false, false,NULL,{
    { 0x90, PG_BASE, "rel", ISA_BASE, },
    { 0x93, PG_BASE, "relw", ISA_CE02, },
}
},
{ "BCS", ISA_BASE + ISA_CE02, false, false, false,NULL,{
    { 0xB0, PG_BASE, "rel", ISA_BASE, },
    { 0xb3, PG_BASE, "relw", ISA_CE02, },
}
},
{ "BGT", ISA_65K, false, false, false,NULL,{
    { 0xB0, PG_EXT, "rel", ISA_BASE, },
}
},
{ "BLE", ISA_65K, false, false, false,NULL,{
    { 0x90, PG_EXT, "rel", ISA_BASE, },
}
},
{ "BNE", ISA_BASE + ISA_CE02, false, false, false,NULL,{
    { 0xD0, PG_BASE, "rel", ISA_BASE, },
    { 0xd3, PG_BASE, "relw", ISA_CE02, },
}
},
{ "BEQ", ISA_BASE + ISA_CE02, false, false, false,NULL,{
    { 0xf0, PG_BASE, "rel", ISA_BASE, },
    { 0xf3, PG_BASE, "relw", ISA_CE02, },
}
},
{ "BRA", ISA_CMOS, false, false, false,NULL,{
    { 0x80, PG_BASE, "rel", ISA_BASE, },
    { 0x83, PG_BASE, "relw", ISA_CE02, },
}
},
{ "BRL", ISA_816, false, false, false,NULL,{
    { 0x82, PG_BASE, "relw", ISA_816CE02, },
}
},
{ "BEV", ISA_65K, false, false, false,NULL,{
    { 0x10, PG_EXT, "rel", ISA_BASE, },
}
},
{ "BOD", ISA_65K, false, false, false,NULL,{
    { 0x30, PG_EXT, "rel", ISA_BASE, },
}
},
{ "BLTS", ISA_65K, false, false, false,NULL,{
    { 0x50, PG_EXT, "rel", ISA_BASE, },
}
},
{ "BGES", ISA_65K, false, false, false,NULL,{
    { 0x70, PG_EXT, "rel", ISA_BASE, },
}
},
{ "BLES", ISA_65K, false, false, false,NULL,{
    { 0xD0, PG_EXT, "rel", ISA_BASE, },
}
},
{ "BGTS", ISA_65K, false, false, false,NULL,{
    { 0xF0, PG_EXT, "rel", ISA_BASE, },
}
},
{ "JMP", ISA_BASE + ISA_816 + ISA_65K + ISA_CMOS, false, false, false,NULL,{
    { 0x07, PG_BASE, "absindquad", ISA_65K, },
    { 0x27, PG_BASE, "absxindquad", ISA_65K, },
    { 0x4c, PG_BASE, "addr", ISA_BASE, },
    { 0x5c, PG_BASE, "addrbank", ISA_816, },
    { 0x6c, PG_BASE, "absind", ISA_BASE, },
    { 0x7c, PG_BASE, "absxind", ISA_CMOS, },
    { 0x4c, PG_EXT, "eind", ISA_65K, },
    { 0x6c, PG_EXT, "addrlong", ISA_65K, },
}
},
{ "JML", ISA_816, false, false, false,NULL,{
    { 0xdc, PG_BASE, "absindbank", ISA_816, },
}
},
{ "JSR", ISA_BASE + ISA_816 + ISA_65K + ISA_CE02, false, false, false,NULL,{
    { 0x20, PG_BASE, "addr", ISA_BASE, },
    { 0xdc, PG_EXT, "addrlong", ISA_65K, },
    { 0xdc, PG_BASE, "absind", ISA_65K, },
    { 0x22, PG_BASE, "absind", ISA_CE02, },
    { 0xfc, PG_BASE, "absxind", ISA_65K, },
    { 0xfc, PG_BASE, "absxind", ISA_816, },
    { 0x23, PG_BASE, "absxind", ISA_CE02, },
    { 0x87, PG_BASE, "absindquad", ISA_65K, },
    { 0xa7, PG_BASE, "absxindquad", ISA_65K, },
    { 0x20, PG_EXT, "eind", ISA_65K, },
}
},
{ "JSL", ISA_816, false, false, false,NULL,{
    { 0x22, PG_BASE, "addrbank", ISA_816, },
}
},
{ "BSR", ISA_65K + ISA_CE02, false, false, false,NULL,{
    { 0x82, PG_BASE, "relj", ISA_65K, },
    { 0x44, PG_BASE, "reljwide", ISA_65K, },
    { 0x63, PG_BASE, "relw", ISA_CE02, },
}
},
{ "RTS", ISA_BASE + ISA_CE02, false, false, false,NULL,{
    { 0x60, PG_BASE, "implied", ISA_BASE, },
    { 0x62, PG_BASE, "imm", ISA_CE02, },
}
},
{ "RTI", ISA_BASE, false, false, false,NULL,{
    { 0x40, PG_BASE, "implied", ISA_BASE, },
}
},
{ "TSB", ISA_CMOS, false, false, false,NULL,{
    { 0x04, PG_BASE, "zp", ISA_BASE, },
    { 0x0c, PG_BASE, "abs", ISA_BASE, },
    { 0x0c, PG_EXT, "eind", ISA_65K, },
}
},
{ "TRB", ISA_CMOS, false, false, false,NULL,{
    { 0x14, PG_BASE, "zp", ISA_BASE, },
    { 0x1c, PG_BASE, "abs", ISA_BASE, },
    { 0x1c, PG_EXT, "eind", ISA_65K, },
}
},
{ "BIT", ISA_BASE + ISA_65K + ISA_CMOS, false, false, false,NULL,{
    { 0x24, PG_BASE, "zp", ISA_BASE, },
    { 0x2c, PG_BASE, "abs", ISA_BASE, },
    { 0x34, PG_BASE, "zpx", ISA_CMOS, },
    { 0x3c, PG_BASE, "absx", ISA_CMOS, },
    { 0x89, PG_BASE, "imm", ISA_CMOS, },
    { 0x89, PG_EXT, "eind", ISA_65K, },
    { 0x34, PG_EXT, "A", ISA_65K, },
}
},
{ "LDY", ISA_BASE + ISA_65K, false, false, false,NULL,{
    { 0xa0, PG_BASE, "imm", ISA_BASE, },
    { 0xa4, PG_BASE, "zp", ISA_BASE, },
    { 0xac, PG_BASE, "abs", ISA_BASE, },
    { 0xb4, PG_BASE, "zpx", ISA_BASE, },
    { 0xbc, PG_BASE, "absx", ISA_BASE, },
    { 0xa0, PG_EXT, "eind", ISA_65K, },
}
},
{ "LDX", ISA_BASE + ISA_65K, false, false, false,NULL,{
    { 0xa2, PG_BASE, "imm", ISA_BASE, },
    { 0xa6, PG_BASE, "zp", ISA_BASE, },
    { 0xae, PG_BASE, "abs", ISA_BASE, },
    { 0xb6, PG_BASE, "zpy", ISA_BASE, },
    { 0xbe, PG_BASE, "absy", ISA_BASE, },
    { 0xad, PG_EXT, "eind", ISA_65K, },
}
},
{ "LDA", ISA_BASE + ISA_816 + ISA_65K + ISA_CMOS_IND + ISA_CMOS_INDZ + ISA_CE02, false, false, false,NULL,{
    { 0x02, PG_BASE, "zpy", ISA_65K, },
    { 0x42, PG_BASE, "absindy", ISA_65K, },
    { 0x47, PG_BASE, "absindyquad", ISA_65K, },
    { 0x62, PG_BASE, "absxind", ISA_65K, },
    { 0x67, PG_BASE, "absxindquad", ISA_65K, },
    { 0xa1, PG_BASE, "zpxind", ISA_BASE, },
    { 0xa3, PG_BASE, "zpxindquad", ISA_65K, },
    { 0xa5, PG_BASE, "zp", ISA_BASE, },
    { 0xa9, PG_BASE, "imm", ISA_BASE, },
    { 0xad, PG_BASE, "abs", ISA_BASE, },
    { 0xb1, PG_BASE, "zpindy", ISA_BASE, },
    { 0xb2, PG_BASE, "zpind", ISA_CMOS_IND, },
    { 0xb2, PG_BASE, "zpindz", ISA_CMOS_INDZ, },
    { 0xb3, PG_BASE, "zpindyquad", ISA_65K, },
    { 0xb5, PG_BASE, "zpx", ISA_BASE, },
    { 0xb7, PG_BASE, "zpindquad", ISA_65K, },
    { 0xb9, PG_BASE, "absy", ISA_BASE, },
    { 0xbd, PG_BASE, "absx", ISA_BASE, },
    { 0xa9, PG_EXT, "eind", ISA_65K, },
    { 0xe2, PG_BASE, "zpsindy", ISA_CE02, },
    { 0xa3, PG_BASE, "zps", ISA_816, },
    { 0xb3, PG_BASE, "zpsindy", ISA_816, },
    { 0xaf, PG_BASE, "bank", ISA_816, },
    { 0xbf, PG_BASE, "bankx", ISA_816, },
    { 0xa7, PG_BASE, "absindbank", ISA_816, },
    { 0xb7, PG_BASE, "absindybank", ISA_816, },
}
},
{ "CPY", ISA_BASE + ISA_65K, false, false, false,NULL,{
    { 0xc0, PG_BASE, "imm", ISA_BASE, },
    { 0xc4, PG_BASE, "zp", ISA_BASE, },
    { 0xcc, PG_BASE, "abs", ISA_BASE, },
    { 0xc0, PG_EXT, "eind", ISA_65K, },
}
},
{ "CPX", ISA_BASE + ISA_65K, false, false, false,NULL,{
    { 0xe0, PG_BASE, "imm", ISA_BASE, },
    { 0xe4, PG_BASE, "zp", ISA_BASE, },
    { 0xec, PG_BASE, "abs", ISA_BASE, },
    { 0xe0, PG_EXT, "eind", ISA_65K, },
}
},
{ "CPZ", ISA_CE02, false, false, false,NULL,{
    { 0xc2, PG_BASE, "imm", ISA_BASE, },
    { 0xd4, PG_BASE, "zp", ISA_BASE, },
    { 0xdc, PG_BASE, "abs", ISA_BASE, },
}
},
{ "CMP", ISA_BASE + ISA_816 + ISA_65K + ISA_CMOS_IND + ISA_CMOS_INDZ, false, false, false,NULL,{
    { 0xc1, PG_BASE, "zpxind", ISA_BASE, },
    { 0xc3, PG_BASE, "zpxindquad", ISA_65K, },
    { 0xc5, PG_BASE, "zp", ISA_BASE, },
    { 0xc9, PG_BASE, "imm", ISA_BASE, },
    { 0xcd, PG_BASE, "abs", ISA_BASE, },
    { 0xd1, PG_BASE, "zpindy", ISA_BASE, },
    { 0xd2, PG_BASE, "zpind", ISA_CMOS_IND, },
    { 0xd2, PG_BASE, "zpindz", ISA_CMOS_INDZ, },
    { 0xd3, PG_BASE, "zpindyquad", ISA_65K, },
    { 0xd7, PG_BASE, "zpindquad", ISA_65K, },
    { 0xd5, PG_BASE, "zpx", ISA_BASE, },
    { 0xd9, PG_BASE, "absy", ISA_BASE, },
    { 0xdd, PG_BASE, "absx", ISA_BASE, },
    { 0xc9, PG_EXT, "eind", ISA_65K, },
    { 0xc3, PG_BASE, "zps", ISA_816, },
    { 0xd3, PG_BASE, "zpsindy", ISA_816, },
    { 0xcf, PG_BASE, "bank", ISA_816, },
    { 0xdf, PG_BASE, "bankx", ISA_816, },
    { 0xc7, PG_BASE, "absindbank", ISA_816, },
    { 0xd7, PG_BASE, "absindybank", ISA_816, },
}
},
{ "ORA", ISA_BASE + ISA_816 + ISA_65K + ISA_CMOS_IND + ISA_CMOS_INDZ, false, false, false,NULL,{
    { 0x01, PG_BASE, "zpxind", ISA_BASE, },
    { 0x03, PG_BASE, "zpxindquad", ISA_65K, },
    { 0x05, PG_BASE, "zp", ISA_BASE, },
    { 0x09, PG_BASE, "imm", ISA_BASE, },
    { 0x0d, PG_BASE, "abs", ISA_BASE, },
    { 0x11, PG_BASE, "zpindy", ISA_BASE, },
    { 0x12, PG_BASE, "zpind", ISA_CMOS_IND, },
    { 0x12, PG_BASE, "zpindz", ISA_CMOS_INDZ, },
    { 0x13, PG_BASE, "zpindyquad", ISA_65K, },
    { 0x15, PG_BASE, "zpx", ISA_BASE, },
    { 0x17, PG_BASE, "zpindquad", ISA_65K, },
    { 0x19, PG_BASE, "absy", ISA_BASE, },
    { 0x1d, PG_BASE, "absx", ISA_BASE, },
    { 0x09, PG_EXT, "eind", ISA_65K, },
    { 0x03, PG_BASE, "zps", ISA_816, },
    { 0x13, PG_BASE, "zpsindy", ISA_816, },
    { 0x0f, PG_BASE, "bank", ISA_816, },
    { 0x1f, PG_BASE, "bankx", ISA_816, },
    { 0x07, PG_BASE, "absindbank", ISA_816, },
    { 0x17, PG_BASE, "absindybank", ISA_816, },
}
},
{ "AND", ISA_BASE + ISA_816 + ISA_65K + ISA_CMOS_IND + ISA_CMOS_INDZ, false, false, false,NULL,{
    { 0x21, PG_BASE, "zpxind", ISA_BASE, },
    { 0x23, PG_BASE, "zpxindquad", ISA_65K, },
    { 0x25, PG_BASE, "zp", ISA_BASE, },
    { 0x29, PG_BASE, "imm", ISA_BASE, },
    { 0x2d, PG_BASE, "abs", ISA_BASE, },
    { 0x31, PG_BASE, "zpindy", ISA_BASE, },
    { 0x32, PG_BASE, "zpind", ISA_CMOS_IND, },
    { 0x32, PG_BASE, "zpindz", ISA_CMOS_INDZ, },
    { 0x33, PG_BASE, "zpindyquad", ISA_65K, },
    { 0x35, PG_BASE, "zpx", ISA_BASE, },
    { 0x37, PG_BASE, "zpindquad", ISA_65K, },
    { 0x39, PG_BASE, "absy", ISA_BASE, },
    { 0x3d, PG_BASE, "absx", ISA_BASE, },
    { 0x29, PG_EXT, "eind", ISA_65K, },
    { 0x23, PG_BASE, "zps", ISA_816, },
    { 0x33, PG_BASE, "zpsindy", ISA_816, },
    { 0x2f, PG_BASE, "bank", ISA_816, },
    { 0x3f, PG_BASE, "bankx", ISA_816, },
    { 0x27, PG_BASE, "absindbank", ISA_816, },
    { 0x37, PG_BASE, "absindybank", ISA_816, },
}
},
{ "EOR", ISA_BASE + ISA_816 + ISA_65K + ISA_CMOS_IND + ISA_CMOS_INDZ, false, false, false,NULL,{
    { 0x41, PG_BASE, "zpxind", ISA_BASE, },
    { 0x43, PG_BASE, "zpxindquad", ISA_65K, },
    { 0x45, PG_BASE, "zp", ISA_BASE, },
    { 0x49, PG_BASE, "imm", ISA_BASE, },
    { 0x4d, PG_BASE, "abs", ISA_BASE, },
    { 0x51, PG_BASE, "zpindy", ISA_BASE, },
    { 0x52, PG_BASE, "zpind", ISA_CMOS_IND, },
    { 0x52, PG_BASE, "zpindz", ISA_CMOS_INDZ, },
    { 0x53, PG_BASE, "zpindyquad", ISA_65K, },
    { 0x55, PG_BASE, "zpx", ISA_BASE, },
    { 0x57, PG_BASE, "zpindquad", ISA_65K, },
    { 0x59, PG_BASE, "absy", ISA_BASE, },
    { 0x5d, PG_BASE, "absx", ISA_BASE, },
    { 0x49, PG_EXT, "eind", ISA_65K, },
    { 0x43, PG_BASE, "zps", ISA_816, },
    { 0x53, PG_BASE, "zpsindy", ISA_816, },
    { 0x4f, PG_BASE, "bank", ISA_816, },
    { 0x5f, PG_BASE, "bankx", ISA_816, },
    { 0x47, PG_BASE, "absindbank", ISA_816, },
    { 0x57, PG_BASE, "absindybank", ISA_816, },
}
},
{ "ADC", ISA_BASE + ISA_816 + ISA_65K + ISA_CMOS_IND + ISA_CMOS_INDZ, false, false, false,NULL,{
    { 0x61, PG_BASE, "zpxind", ISA_BASE, },
    { 0x63, PG_BASE, "zpxindquad", ISA_65K, },
    { 0x65, PG_BASE, "zp", ISA_BASE, },
    { 0x69, PG_BASE, "imm", ISA_BASE, },
    { 0x6d, PG_BASE, "abs", ISA_BASE, },
    { 0x71, PG_BASE, "zpindy", ISA_BASE, },
    { 0x72, PG_BASE, "zpind", ISA_CMOS_IND, },
    { 0x72, PG_BASE, "zpindz", ISA_CMOS_INDZ, },
    { 0x73, PG_BASE, "zpindyquad", ISA_65K, },
    { 0x75, PG_BASE, "zpx", ISA_BASE, },
    { 0x77, PG_BASE, "zpindquad", ISA_65K, },
    { 0x79, PG_BASE, "absy", ISA_BASE, },
    { 0x7d, PG_BASE, "absx", ISA_BASE, },
    { 0x69, PG_EXT, "eind", ISA_65K, },
    { 0x63, PG_BASE, "zps", ISA_816, },
    { 0x73, PG_BASE, "zpsindy", ISA_816, },
    { 0x6f, PG_BASE, "bank", ISA_816, },
    { 0x7f, PG_BASE, "bankx", ISA_816, },
    { 0x67, PG_BASE, "absindbank", ISA_816, },
    { 0x77, PG_BASE, "absindybank", ISA_816, },
}
},
{ "DAD", ISA_65K, false, false, false,NULL,{
    { 0x1a, PG_EXT, "implied", ISA_BASE, },
}
},
{ "DAS", ISA_65K, false, false, false,NULL,{
    { 0x3a, PG_EXT, "implied", ISA_BASE, },
}
},
{ "ADD", ISA_65K, false, false, false,NULL,{
    { 0x05, PG_EXT, "imm", ISA_BASE, },
    { 0x00, PG_EXT, "eind", ISA_65K, },
}
},
{ "SBC", ISA_UNDOC + ISA_BASE + ISA_816 + ISA_65K + ISA_CMOS_IND + ISA_CMOS_INDZ, false, false, false,NULL,{
    { 0xe1, PG_BASE, "zpxind", ISA_BASE, },
    { 0xe3, PG_BASE, "zpxindquad", ISA_65K, },
    { 0xe5, PG_BASE, "zp", ISA_BASE, },
    { 0xe9, PG_BASE, "imm", ISA_BASE, },
    { 0xeb, PG_BASE, "imm", ISA_UNDOC, },
    { 0xed, PG_BASE, "abs", ISA_BASE, },
    { 0xf1, PG_BASE, "zpindy", ISA_BASE, },
    { 0xf2, PG_BASE, "zpind", ISA_CMOS_IND, },
    { 0xf2, PG_BASE, "zpindz", ISA_CMOS_INDZ, },
    { 0xf3, PG_BASE, "zpindyquad", ISA_65K, },
    { 0xf5, PG_BASE, "zpx", ISA_BASE, },
    { 0xf7, PG_BASE, "zpindquad", ISA_65K, },
    { 0xf9, PG_BASE, "absy", ISA_BASE, },
    { 0xfd, PG_BASE, "absx", ISA_BASE, },
    { 0xe9, PG_EXT, "eind", ISA_65K, },
    { 0xe3, PG_BASE, "zps", ISA_816, },
    { 0xf3, PG_BASE, "zpsindy", ISA_816, },
    { 0xef, PG_BASE, "bank", ISA_816, },
    { 0xff, PG_BASE, "bankx", ISA_816, },
    { 0xe7, PG_BASE, "absindbank", ISA_816, },
    { 0xf7, PG_BASE, "absindybank", ISA_816, },
}
},
{ "SUB", ISA_65K, false, false, false,NULL,{
    { 0x85, PG_EXT, "imm", ISA_BASE, },
    { 0x80, PG_EXT, "eind", ISA_65K, },
}
},
{ "ASR", ISA_65K + ISA_CE02, false, false, false,NULL,{
    { 0x43, PG_BASE, "A", ISA_CE02, },
    { 0x06, PG_EXT, "zp", ISA_65K, },
    { 0x44, PG_BASE, "zp", ISA_CE02, },
    { 0x0a, PG_EXT, "A", ISA_65K, },
    { 0x0e, PG_EXT, "abs", ISA_65K, },
    { 0x16, PG_EXT, "zpx", ISA_65K, },
    { 0x54, PG_BASE, "zpx", ISA_CE02, },
    { 0x1e, PG_EXT, "absx", ISA_65K, },
    { 0x1f, PG_EXT, "absy", ISA_65K, },
    { 0x1d, PG_EXT, "eind", ISA_65K, },
}
},
{ "RDL", ISA_65K, false, false, false,NULL,{
    { 0x26, PG_EXT, "zp", ISA_BASE, },
    { 0x2a, PG_EXT, "A", ISA_BASE, },
    { 0x2e, PG_EXT, "abs", ISA_BASE, },
    { 0x36, PG_EXT, "zpx", ISA_BASE, },
    { 0x3e, PG_EXT, "absx", ISA_BASE, },
    { 0x3f, PG_EXT, "absy", ISA_BASE, },
    { 0x3d, PG_EXT, "eind", ISA_65K, },
}
},
{ "RDR", ISA_65K, false, false, false,NULL,{
    { 0x66, PG_EXT, "zp", ISA_BASE, },
    { 0x6a, PG_EXT, "A", ISA_BASE, },
    { 0x6e, PG_EXT, "abs", ISA_BASE, },
    { 0x76, PG_EXT, "zpx", ISA_BASE, },
    { 0x7e, PG_EXT, "absx", ISA_BASE, },
    { 0x7f, PG_EXT, "absy", ISA_BASE, },
    { 0x7d, PG_EXT, "eind", ISA_65K, },
}
},
{ "ASL", ISA_BASE + ISA_65K, false, false, false,NULL,{
    { 0x06, PG_BASE, "zp", ISA_BASE, },
    { 0x0a, PG_BASE, "A", ISA_BASE, },
    { 0x0e, PG_BASE, "abs", ISA_BASE, },
    { 0x16, PG_BASE, "zpx", ISA_BASE, },
    { 0x1e, PG_BASE, "absx", ISA_BASE, },
    { 0x0f, PG_EXT, "absy", ISA_65K, },
    { 0x0d, PG_EXT, "eind", ISA_65K, },
}
},
{ "LSR", ISA_BASE + ISA_65K, false, false, false,NULL,{
    { 0x46, PG_BASE, "zp", ISA_BASE, },
    { 0x4a, PG_BASE, "A", ISA_BASE, },
    { 0x4e, PG_BASE, "abs", ISA_BASE, },
    { 0x56, PG_BASE, "zpx", ISA_BASE, },
    { 0x5e, PG_BASE, "absx", ISA_BASE, },
    { 0x4f, PG_EXT, "absy", ISA_65K, },
    { 0x4d, PG_EXT, "eind", ISA_65K, },
}
},
{ "ROL", ISA_BASE + ISA_65K, false, false, false,NULL,{
    { 0x26, PG_BASE, "zp", ISA_BASE, },
    { 0x2a, PG_BASE, "A", ISA_BASE, },
    { 0x2e, PG_BASE, "abs", ISA_BASE, },
    { 0x36, PG_BASE, "zpx", ISA_BASE, },
    { 0x3e, PG_BASE, "absx", ISA_BASE, },
    { 0x2f, PG_EXT, "absy", ISA_65K, },
    { 0x2d, PG_EXT, "eind", ISA_65K, },
}
},
{ "ROR", ISA_ROR, false, false, false,NULL,{
    { 0x66, PG_BASE, "zp", ISA_BASE, },
    { 0x6a, PG_BASE, "A", ISA_BASE, },
    { 0x6e, PG_BASE, "abs", ISA_BASE, },
    { 0x76, PG_BASE, "zpx", ISA_BASE, },
    { 0x7e, PG_BASE, "absx", ISA_BASE, },
    { 0x6f, PG_EXT, "absy", ISA_65K, },
    { 0x6d, PG_EXT, "eind", ISA_65K, },
}
},
{ "INC", ISA_BASE + ISA_65K + ISA_CMOS, false, false, false,NULL,{
    { 0xe6, PG_BASE, "zp", ISA_BASE, },
    { 0x1a, PG_BASE, "A", ISA_CMOS, },
    { 0xee, PG_BASE, "abs", ISA_BASE, },
    { 0xf6, PG_BASE, "zpx", ISA_BASE, },
    { 0xfe, PG_BASE, "absx", ISA_BASE, },
    { 0xef, PG_EXT, "absy", ISA_65K, },
    { 0xed, PG_EXT, "eind", ISA_65K, },
}
},
{ "DEC", ISA_BASE + ISA_65K + ISA_CMOS, false, false, false,NULL,{
    { 0xc6, PG_BASE, "zp", ISA_BASE, },
    { 0x3a, PG_BASE, "A", ISA_CMOS, },
    { 0xce, PG_BASE, "abs", ISA_BASE, },
    { 0xd6, PG_BASE, "zpx", ISA_BASE, },
    { 0xde, PG_BASE, "absx", ISA_BASE, },
    { 0xcf, PG_EXT, "absy", ISA_65K, },
    { 0xcd, PG_EXT, "eind", ISA_65K, },
}
},
{ "STA", ISA_BASE + ISA_816 + ISA_65K + ISA_CMOS_IND + ISA_CMOS_INDZ + ISA_CE02, false, false, false,NULL,{
    { 0x22, PG_BASE, "zpy", ISA_65K, },
    { 0x81, PG_BASE, "zpxind", ISA_BASE, },
    { 0x83, PG_BASE, "zpxindquad", ISA_65K, },
    { 0x85, PG_BASE, "zp", ISA_BASE, },
    { 0x8d, PG_BASE, "abs", ISA_BASE, },
    { 0x91, PG_BASE, "zpindy", ISA_BASE, },
    { 0x92, PG_BASE, "zpind", ISA_CMOS_IND, },
    { 0x92, PG_BASE, "zpindz", ISA_CMOS_INDZ, },
    { 0x93, PG_BASE, "zpindyquad", ISA_65K, },
    { 0x95, PG_BASE, "zpx", ISA_BASE, },
    { 0x97, PG_BASE, "zpindquad", ISA_65K, },
    { 0x99, PG_BASE, "absy", ISA_BASE, },
    { 0x9d, PG_BASE, "absx", ISA_BASE, },
    { 0xc2, PG_BASE, "absindy", ISA_65K, },
    { 0xc7, PG_BASE, "absindyquad", ISA_65K, },
    { 0xe2, PG_BASE, "absxind", ISA_65K, },
    { 0xe7, PG_BASE, "absxindquad", ISA_65K, },
    { 0x8d, PG_EXT, "eind", ISA_65K, },
    { 0x82, PG_BASE, "zpsindy", ISA_CE02, },
    { 0x83, PG_BASE, "zps", ISA_816, },
    { 0x93, PG_BASE, "zpsindy", ISA_816, },
    { 0x8f, PG_BASE, "bank", ISA_816, },
    { 0x9f, PG_BASE, "bankx", ISA_816, },
    { 0x87, PG_BASE, "absindbank", ISA_816, },
    { 0x97, PG_BASE, "absindybank", ISA_816, },
}
},
{ "STZ", ISA_CMOS, false, false, false,NULL,{
    { 0x64, PG_BASE, "zp", ISA_BASE, },
    { 0x74, PG_BASE, "zpx", ISA_BASE, },
    { 0x9c, PG_BASE, "abs", ISA_BASE, },
    { 0x9e, PG_BASE, "absx", ISA_BASE, },
    { 0x9e, PG_EXT, "absy", ISA_65K, },
    { 0x9c, PG_EXT, "eind", ISA_65K, },
}
},
{ "STY", ISA_BASE + ISA_65K + ISA_CE02, false, false, false,NULL,{
    { 0x84, PG_BASE, "zp", ISA_BASE, },
    { 0x8c, PG_BASE, "abs", ISA_BASE, },
    { 0x94, PG_BASE, "zpx", ISA_BASE, },
    { 0x8f, PG_EXT, "absx", ISA_65K, },
    { 0x8b, PG_BASE, "absx", ISA_CE02, },
    { 0x8c, PG_EXT, "eind", ISA_65K, },
}
},
{ "STX", ISA_BASE + ISA_65K + ISA_CE02, false, false, false,NULL,{
    { 0x86, PG_BASE, "zp", ISA_BASE, },
    { 0x8e, PG_BASE, "abs", ISA_BASE, },
    { 0x96, PG_BASE, "zpy", ISA_BASE, },
    { 0xaf, PG_EXT, "absy", ISA_65K, },
    { 0x9b, PG_BASE, "absy", ISA_CE02, },
    { 0x9d, PG_EXT, "eind", ISA_65K, },
}
},
{ "TRP", ISA_65K, false, false, false,NULL,{
    { 0xf4, PG_BASE, "imm", ISA_BASE, },
}
},
{ "RTU", ISA_65K, false, false, false,NULL,{
    { 0x60, PG_SYS, "imm", ISA_BASE, },
}
},
{ "PHP", ISA_BASE, false, false, false,NULL,{
    { 0x08, PG_BASE, "implied", ISA_BASE, },
}
},
{ "CLC", ISA_BASE, false, false, false,NULL,{
    { 0x18, PG_BASE, "implied", ISA_BASE, },
}
},
{ "PLP", ISA_BASE, false, false, false,NULL,{
    { 0x28, PG_BASE, "implied", ISA_BASE, },
}
},
{ "SEC", ISA_BASE, false, false, false,NULL,{
    { 0x38, PG_BASE, "implied", ISA_BASE, },
}
},
{ "PHA", ISA_BASE, false, false, false,NULL,{
    { 0x48, PG_BASE, "implied", ISA_BASE, },
}
},
{ "PHY", ISA_CMOS, false, false, false,NULL,{
    { 0x5a, PG_BASE, "implied", ISA_BASE, },
}
},
{ "PHX", ISA_CMOS, false, false, false,NULL,{
    { 0xda, PG_BASE, "implied", ISA_BASE, },
}
},
{ "CLI", ISA_BASE, false, false, false,NULL,{
    { 0x58, PG_BASE, "implied", ISA_BASE, },
}
},
{ "PLA", ISA_BASE, false, false, false,NULL,{
    { 0x68, PG_BASE, "implied", ISA_BASE, },
}
},
{ "PLY", ISA_CMOS, false, false, false,NULL,{
    { 0x7a, PG_BASE, "implied", ISA_BASE, },
}
},
{ "PLX", ISA_CMOS, false, false, false,NULL,{
    { 0xfa, PG_BASE, "implied", ISA_BASE, },
}
},
{ "SEI", ISA_BASE, false, false, false,NULL,{
    { 0x78, PG_BASE, "implied", ISA_BASE, },
}
},
{ "DEY", ISA_BASE, false, false, false,NULL,{
    { 0x88, PG_BASE, "implied", ISA_BASE, },
}
},
{ "TYA", ISA_BASE, false, false, false,NULL,{
    { 0x98, PG_BASE, "implied", ISA_BASE, },
}
},
{ "TXA", ISA_BASE, false, false, false,NULL,{
    { 0x8a, PG_BASE, "implied", ISA_BASE, },
}
},
{ "TSX", ISA_BASE, false, false, false,NULL,{
    { 0xba, PG_BASE, "implied", ISA_BASE, },
}
},
{ "TXS", ISA_BASE, false, false, false,NULL,{
    { 0x9a, PG_BASE, "implied", ISA_BASE, },
}
},
{ "TAY", ISA_BASE, false, false, false,NULL,{
    { 0xa8, PG_BASE, "implied", ISA_BASE, },
}
},
{ "TAX", ISA_BASE, false, false, false,NULL,{
    { 0xaa, PG_BASE, "implied", ISA_BASE, },
}
},
{ "CLV", ISA_BASE, false, false, false,NULL,{
    { 0xb8, PG_BASE, "implied", ISA_BASE, },
}
},
{ "INY", ISA_BASE, false, false, false,NULL,{
    { 0xc8, PG_BASE, "implied", ISA_BASE, },
}
},
{ "CLD", ISA_BASE, false, false, false,NULL,{
    { 0xd8, PG_BASE, "implied", ISA_BASE, },
}
},
{ "INX", ISA_BASE, false, false, false,NULL,{
    { 0xe8, PG_BASE, "implied", ISA_BASE, },
}
},
{ "DEX", ISA_BASE, false, false, false,NULL,{
    { 0xca, PG_BASE, "implied", ISA_BASE, },
}
},
{ "SED", ISA_BCD, false, false, false,NULL,{
    { 0xf8, PG_BASE, "implied", ISA_BASE, },
}
},
{ "NOP", ISA_UNDOC + ISA_BASE, false, false, false,NULL,{
    { 0xea, PG_BASE, "implied", ISA_BASE, },
    { 0x1a, PG_BASE, "implied", ISA_UNDOC, },
    { 0x3a, PG_BASE, "implied", ISA_UNDOC, },
    { 0x5a, PG_BASE, "implied", ISA_UNDOC, },
    { 0x7a, PG_BASE, "implied", ISA_UNDOC, },
    { 0xda, PG_BASE, "implied", ISA_UNDOC, },
    { 0xfa, PG_BASE, "implied", ISA_UNDOC, },
    { 0x80, PG_BASE, "implied", ISA_UNDOC, },
    { 0x04, PG_BASE, "zp", ISA_UNDOC, },
    { 0x14, PG_BASE, "zpx", ISA_UNDOC, },
    { 0x34, PG_BASE, "zpx", ISA_UNDOC, },
    { 0x44, PG_BASE, "zp", ISA_UNDOC, },
    { 0x54, PG_BASE, "zpx", ISA_UNDOC, },
    { 0x64, PG_BASE, "zp", ISA_UNDOC, },
    { 0x74, PG_BASE, "zpx", ISA_UNDOC, },
    { 0xd4, PG_BASE, "zpx", ISA_UNDOC, },
    { 0xf4, PG_BASE, "zpx", ISA_UNDOC, },
    { 0x0c, PG_BASE, "abs", ISA_UNDOC, },
    { 0x1c, PG_BASE, "absx", ISA_UNDOC, },
    { 0x3c, PG_BASE, "absx", ISA_UNDOC, },
    { 0x5c, PG_BASE, "absx", ISA_UNDOC, },
    { 0x7c, PG_BASE, "absx", ISA_UNDOC, },
    { 0xdc, PG_BASE, "absx", ISA_UNDOC, },
    { 0xfc, PG_BASE, "absx", ISA_UNDOC, },
    { 0x89, PG_BASE, "imm", ISA_UNDOC, },
}
},
{ "LEA", ISA_65K, false, false, false,NULL,{
    { 0xf6, PG_EXT, "zpy", ISA_BASE, },
    { 0x61, PG_EXT, "absindyquad", ISA_65K, },
    { 0x71, PG_EXT, "absxindquad", ISA_65K, },
    { 0x21, PG_EXT, "absindy", ISA_65K, },
    { 0x31, PG_EXT, "absxind", ISA_65K, },
    { 0xa2, PG_EXT, "rel", ISA_BASE, },
    { 0xa1, PG_EXT, "zpxind", ISA_BASE, },
    { 0x46, PG_EXT, "zp", ISA_BASE, },
    { 0xae, PG_EXT, "abs", ISA_BASE, },
    { 0xb1, PG_EXT, "zpindy", ISA_BASE, },
    { 0xb2, PG_EXT, "zpind", ISA_65K, },
    { 0x32, PG_EXT, "absind", ISA_BASE, },
    { 0xf2, PG_EXT, "zpindquad", ISA_65K, },
    { 0x72, PG_EXT, "absindquad", ISA_65K, },
    { 0x56, PG_EXT, "zpx", ISA_BASE, },
    { 0xbf, PG_EXT, "absy", ISA_BASE, },
    { 0xbe, PG_EXT, "absx", ISA_BASE, },
    { 0x22, PG_EXT, "relwide", ISA_65K, },
    { 0xe1, PG_EXT, "zpindyquad", ISA_65K, },
    { 0xf1, PG_EXT, "zpxindquad", ISA_65K, },
}
},
{ "PEA", ISA_65K, false, false, false,NULL,{
    { 0x41, PG_EXT, "absindyquad", ISA_65K, },
    { 0x51, PG_EXT, "absxindquad", ISA_65K, },
    { 0xd6, PG_EXT, "zpy", ISA_BASE, },
    { 0x01, PG_EXT, "absindy", ISA_65K, },
    { 0x11, PG_EXT, "absxind", ISA_65K, },
    { 0x82, PG_EXT, "rel", ISA_BASE, },
    { 0x81, PG_EXT, "zpxind", ISA_BASE, },
    { 0x86, PG_EXT, "zp", ISA_BASE, },
    { 0xce, PG_EXT, "abs", ISA_BASE, },
    { 0x91, PG_EXT, "zpindy", ISA_BASE, },
    { 0x92, PG_EXT, "zpind", ISA_65K, },
    { 0x12, PG_EXT, "absind", ISA_BASE, },
    { 0xd2, PG_EXT, "zpindquad", ISA_65K, },
    { 0x52, PG_EXT, "absindquad", ISA_65K, },
    { 0x96, PG_EXT, "zpx", ISA_BASE, },
    { 0xdf, PG_EXT, "absy", ISA_BASE, },
    { 0xde, PG_EXT, "absx", ISA_BASE, },
    { 0x02, PG_EXT, "relwide", ISA_65K, },
    { 0xc1, PG_EXT, "zpindyquad", ISA_65K, },
    { 0xd1, PG_EXT, "zpxindquad", ISA_65K, },
}
},
{ "MVN", ISA_65K10, false, false, false,NULL,{
    { 0x04, PG_EXT, "implied", ISA_BASE, },
}
},
{ "MVP", ISA_65K10, false, false, false,NULL,{
    { 0x14, PG_EXT, "implied", ISA_BASE, },
}
},
{ "FIL", ISA_65K10, false, false, false,NULL,{
    { 0x24, PG_EXT, "implied", ISA_BASE, },
}
},
{ "WMB", ISA_65K10, false, false, false,NULL,{
    { 0x74, PG_EXT, "implied", ISA_BASE, },
    { 0xfc, PG_EXT, "eind", ISA_65K, },
}
},
{ "RMB", ISA_65K10, false, false, false,NULL,{
    { 0x64, PG_EXT, "implied", ISA_BASE, },
    { 0xec, PG_EXT, "eind", ISA_65K, },
}
},
{ "SCA", ISA_65K10, false, false, false,NULL,{
    { 0x2c, PG_EXT, "eind", ISA_65K, },
}
},
{ "LLA", ISA_65K10, false, false, false,NULL,{
    { 0x3c, PG_EXT, "eind", ISA_65K, },
}
},
{ "BCN", ISA_65K, false, false, false,NULL,{
    { 0xb4, PG_EXT, "A", ISA_BASE, },
}
},
{ "BSW", ISA_65K, false, false, false,NULL,{
    { 0xf4, PG_EXT, "A", ISA_BASE, },
}
},
{ "HBS", ISA_65K10, false, false, false,NULL,{
    { 0x84, PG_EXT, "A", ISA_BASE, },
}
},
{ "HBC", ISA_65K10, false, false, false,NULL,{
    { 0x94, PG_EXT, "A", ISA_BASE, },
}
},
{ "PSH", ISA_65K10, false, false, false,NULL,{
    { 0x44, PG_EXT, "implied", ISA_BASE, },
}
},
{ "PLL", ISA_65K10, false, false, false,NULL,{
    { 0x54, PG_EXT, "implied", ISA_BASE, },
}
},
{ "INV", ISA_65K + ISA_CE02, false, false, false,NULL,{
    { 0xa4, PG_EXT, "A", ISA_65K, },
    { 0x42, PG_BASE, "A", ISA_CE02, },
}
},
{ "SWP", ISA_65K, false, false, false,NULL,{
    { 0xd4, PG_EXT, "A", ISA_BASE, },
}
},
{ "EXT", ISA_65K, false, false, false,NULL,{
    { 0xc4, PG_EXT, "A", ISA_BASE, },
}
},
{ "LDE", ISA_65K, false, false, false,NULL,{
    { 0x39, PG_EXT, "imm", ISA_BASE, },
}
},
{ "LDB", ISA_65K, false, false, false,NULL,{
    { 0x59, PG_EXT, "imm", ISA_BASE, },
}
},
{ "PHE", ISA_65K, false, false, false,NULL,{
    { 0x08, PG_EXT, "implied", ISA_BASE, },
}
},
{ "PLE", ISA_65K, false, false, false,NULL,{
    { 0x28, PG_EXT, "implied", ISA_BASE, },
}
},
{ "PHB", ISA_65K, false, false, false,NULL,{
    { 0x48, PG_EXT, "implied", ISA_BASE, },
}
},
{ "PRB", ISA_65K, false, false, false,NULL,{
    { 0x58, PG_EXT, "implied", ISA_BASE, },
}
},
{ "PLB", ISA_65K, false, false, false,NULL,{
    { 0x68, PG_EXT, "implied", ISA_BASE, },
}
},
{ "TPA", ISA_65K, false, false, false,NULL,{
    { 0xc8, PG_EXT, "implied", ISA_BASE, },
}
},
{ "TBA", ISA_65K + ISA_CE02, false, false, false,NULL,{
    { 0xf8, PG_EXT, "implied", ISA_65K, },
    { 0x7b, PG_BASE, "implied", ISA_CE02, },
}
},
{ "TEA", ISA_65K, false, false, false,NULL,{
    { 0x98, PG_EXT, "implied", ISA_BASE, },
}
},
{ "TAE", ISA_65K, false, false, false,NULL,{
    { 0x88, PG_EXT, "implied", ISA_BASE, },
}
},
{ "TYS", ISA_65K + ISA_CE02, false, false, false,NULL,{
    { 0x8a, PG_EXT, "implied", ISA_65K, },
    { 0x2b, PG_BASE, "implied", ISA_CE02, },
}
},
{ "TSY", ISA_65K + ISA_CE02, false, false, false,NULL,{
    { 0xca, PG_EXT, "implied", ISA_65K, },
    { 0x0b, PG_BASE, "implied", ISA_CE02, },
}
},
{ "TAB", ISA_65K + ISA_CE02, false, false, false,NULL,{
    { 0xe8, PG_EXT, "implied", ISA_65K, },
    { 0x5b, PG_BASE, "implied", ISA_CE02, },
}
},
{ "TEB", ISA_65K, false, false, false,NULL,{
    { 0xea, PG_EXT, "implied", ISA_BASE, },
}
},
{ "TBE", ISA_65K, false, false, false,NULL,{
    { 0xfa, PG_EXT, "implied", ISA_BASE, },
}
},
{ "SEB", ISA_65K, false, false, false,NULL,{
    { 0xb8, PG_EXT, "implied", ISA_BASE, },
}
},
{ "SAB", ISA_65K, false, false, false,NULL,{
    { 0xa8, PG_EXT, "implied", ISA_BASE, },
}
},
{ "SAE", ISA_65K, false, false, false,NULL,{
    { 0xd8, PG_EXT, "implied", ISA_BASE, },
}
},
{ "SAX", ISA_65K, false, false, false,NULL,{
    { 0xba, PG_EXT, "implied", ISA_BASE, },
}
},
{ "SAY", ISA_65K, false, false, false,NULL,{
    { 0xda, PG_EXT, "implied", ISA_BASE, },
}
},
{ "SXY", ISA_65K, false, false, false,NULL,{
    { 0x9a, PG_EXT, "implied", ISA_BASE, },
}
},
{ "ADE", ISA_65K, false, false, false,NULL,{
    { 0x25, PG_EXT, "imm", ISA_BASE, },
    { 0x35, PG_EXT, "A", ISA_BASE, },
}
},
{ "ADS", ISA_65K, false, false, false,NULL,{
    { 0x45, PG_EXT, "imm", ISA_BASE, },
    { 0x55, PG_EXT, "A", ISA_BASE, },
}
},
{ "ADB", ISA_65K, false, false, false,NULL,{
    { 0x65, PG_EXT, "imm", ISA_BASE, },
    { 0x75, PG_EXT, "A", ISA_BASE, },
}
},
{ "SBE", ISA_65K, false, false, false,NULL,{
    { 0xa5, PG_EXT, "imm", ISA_BASE, },
    { 0xb5, PG_EXT, "A", ISA_BASE, },
}
},
{ "SBS", ISA_65K, false, false, false,NULL,{
    { 0xc5, PG_EXT, "imm", ISA_BASE, },
    { 0xd5, PG_EXT, "A", ISA_BASE, },
}
},
{ "SBB", ISA_65K, false, false, false,NULL,{
    { 0xe5, PG_EXT, "imm", ISA_BASE, },
    { 0xf5, PG_EXT, "A", ISA_BASE, },
}
},
{ "ASO", ISA_UNDOC, false, false, false,NULL,{
    { 0x0f, PG_BASE, "abs", ISA_BASE, },
    { 0x1f, PG_BASE, "absx", ISA_BASE, },
    { 0x1b, PG_BASE, "absy", ISA_BASE, },
    { 0x07, PG_BASE, "zp", ISA_BASE, },
    { 0x17, PG_BASE, "zpx", ISA_BASE, },
    { 0x03, PG_BASE, "zpxind", ISA_BASE, },
    { 0x13, PG_BASE, "zpindy", ISA_BASE, },
}
},
{ "RLA", ISA_UNDOC, false, false, false,NULL,{
    { 0x2f, PG_BASE, "abs", ISA_BASE, },
    { 0x3f, PG_BASE, "absx", ISA_BASE, },
    { 0x3b, PG_BASE, "absy", ISA_BASE, },
    { 0x27, PG_BASE, "zp", ISA_BASE, },
    { 0x37, PG_BASE, "zpx", ISA_BASE, },
    { 0x23, PG_BASE, "zpxind", ISA_BASE, },
    { 0x33, PG_BASE, "zpindy", ISA_BASE, },
}
},
{ "LSE", ISA_UNDOC, false, false, false,NULL,{
    { 0x4f, PG_BASE, "abs", ISA_BASE, },
    { 0x5f, PG_BASE, "absx", ISA_BASE, },
    { 0x5b, PG_BASE, "absy", ISA_BASE, },
    { 0x47, PG_BASE, "zp", ISA_BASE, },
    { 0x57, PG_BASE, "zpx", ISA_BASE, },
    { 0x43, PG_BASE, "zpxind", ISA_BASE, },
    { 0x53, PG_BASE, "zpindy", ISA_BASE, },
}
},
{ "RRA", ISA_UNDOC, false, false, false,NULL,{
    { 0x6f, PG_BASE, "abs", ISA_BASE, },
    { 0x7f, PG_BASE, "absx", ISA_BASE, },
    { 0x7b, PG_BASE, "absy", ISA_BASE, },
    { 0x67, PG_BASE, "zp", ISA_BASE, },
    { 0x77, PG_BASE, "zpx", ISA_BASE, },
    { 0x63, PG_BASE, "zpxind", ISA_BASE, },
    { 0x73, PG_BASE, "zpindy", ISA_BASE, },
}
},
{ "SAX", ISA_UNDOC, false, false, false,NULL,{
    { 0x8f, PG_BASE, "abs", ISA_BASE, },
    { 0x87, PG_BASE, "zp", ISA_BASE, },
    { 0x97, PG_BASE, "zpy", ISA_BASE, },
    { 0x83, PG_BASE, "zpxind", ISA_BASE, },
}
},
{ "LAX", ISA_UNDOC, false, false, false,NULL,{
    { 0xaf, PG_BASE, "abs", ISA_BASE, },
    { 0xbf, PG_BASE, "absy", ISA_BASE, },
    { 0xa7, PG_BASE, "zp", ISA_BASE, },
    { 0xb7, PG_BASE, "zpy", ISA_BASE, },
    { 0xa3, PG_BASE, "zpxind", ISA_BASE, },
    { 0xb3, PG_BASE, "zpindy", ISA_BASE, },
}
},
{ "DCM", ISA_UNDOC, false, false, false,NULL,{
    { 0xcf, PG_BASE, "abs", ISA_BASE, },
    { 0xdf, PG_BASE, "absx", ISA_BASE, },
    { 0xdb, PG_BASE, "absy", ISA_BASE, },
    { 0xc7, PG_BASE, "zp", ISA_BASE, },
    { 0xd7, PG_BASE, "zpx", ISA_BASE, },
    { 0xc3, PG_BASE, "zpxind", ISA_BASE, },
    { 0xd3, PG_BASE, "zpindy", ISA_BASE, },
}
},
{ "INS", ISA_UNDOC, false, false, false,NULL,{
    { 0xef, PG_BASE, "abs", ISA_BASE, },
    { 0xff, PG_BASE, "absx", ISA_BASE, },
    { 0xfb, PG_BASE, "absy", ISA_BASE, },
    { 0xe7, PG_BASE, "zp", ISA_BASE, },
    { 0xf7, PG_BASE, "zpx", ISA_BASE, },
    { 0xe3, PG_BASE, "zpxind", ISA_BASE, },
    { 0xf3, PG_BASE, "zpindy", ISA_BASE, },
}
},
{ "ALR", ISA_UNDOC, false, false, false,NULL,{
    { 0x4b, PG_BASE, "imm", ISA_BASE, },
}
},
{ "ANE", ISA_UNDOC, false, false, false,NULL,{
    { 0x8b, PG_BASE, "imm", ISA_BASE, },
}
},
{ "LXA", ISA_UNDOC, false, false, false,NULL,{
    { 0xab, PG_BASE, "imm", ISA_BASE, },
}
},
{ "SBX", ISA_UNDOC, false, false, false,NULL,{
    { 0xcb, PG_BASE, "imm", ISA_BASE, },
}
},
{ "HLT", ISA_UNDOC, false, false, false,NULL,{
    { 0x02, PG_BASE, "implied", ISA_BASE, },
    { 0x12, PG_BASE, "implied", ISA_BASE, },
    { 0x22, PG_BASE, "implied", ISA_BASE, },
    { 0x32, PG_BASE, "implied", ISA_BASE, },
    { 0x42, PG_BASE, "implied", ISA_BASE, },
    { 0x52, PG_BASE, "implied", ISA_BASE, },
    { 0x62, PG_BASE, "implied", ISA_BASE, },
    { 0x72, PG_BASE, "implied", ISA_BASE, },
    { 0x82, PG_BASE, "implied", ISA_BASE, },
    { 0x92, PG_BASE, "implied", ISA_BASE, },
    { 0xb2, PG_BASE, "implied", ISA_BASE, },
    { 0xc2, PG_BASE, "implied", ISA_BASE, },
    { 0xd2, PG_BASE, "implied", ISA_BASE, },
    { 0xe2, PG_BASE, "implied", ISA_BASE, },
    { 0xf2, PG_BASE, "implied", ISA_BASE, },
}
},
{ "SHS", ISA_UNDOC, false, false, false,NULL,{
    { 0x9b, PG_BASE, "absy", ISA_BASE, },
}
},
{ "SHY", ISA_UNDOC, false, false, false,NULL,{
    { 0x9c, PG_BASE, "absx", ISA_BASE, },
}
},
{ "SHX", ISA_UNDOC, false, false, false,NULL,{
    { 0x9e, PG_BASE, "absy", ISA_BASE, },
}
},
{ "SHA", ISA_UNDOC, false, false, false,NULL,{
    { 0x9f, PG_BASE, "absy", ISA_BASE, },
    { 0x93, PG_BASE, "zpindy", ISA_BASE, },
}
},
{ "ANC", ISA_UNDOC, false, false, false,NULL,{
    { 0x0b, PG_BASE, "zp", ISA_BASE, },
    { 0x2b, PG_BASE, "zp", ISA_BASE, },
}
},
{ "LAS", ISA_UNDOC, false, false, false,NULL,{
    { 0xbb, PG_BASE, "absy", ISA_BASE, },
}
},
{ "ARR", ISA_UNDOC, false, false, false,NULL,{
    { 0x6b, PG_BASE, "absy", ISA_BASE, },
}
},
{ "RMB", ISA_RCMOS, false, false, false,NULL,{
    { 0x07, PG_BASE, "zp", ISA_BASE, },
}
},
{ "SMB", ISA_RCMOS, false, false, false,NULL,{
    { 0x87, PG_BASE, "zp", ISA_BASE, },
}
},
{ "BBR", ISA_RCMOS, false, false, false,NULL,{
    { 0x0f, PG_BASE, "zprel", ISA_RCMOS, },
}
},
{ "BBS", ISA_RCMOS, false, false, false,NULL,{
    { 0x8f, PG_BASE, "zprel", ISA_RCMOS, },
}
},
{ "CLE", ISA_CE02, false, false, false,NULL,{
    { 0x02, PG_BASE, "implied", ISA_BASE, },
}
},
{ "SEE", ISA_CE02, false, false, false,NULL,{
    { 0x03, PG_BASE, "implied", ISA_BASE, },
}
},
{ "AUG", ISA_CE02, false, false, false,NULL,{
    { 0x5c, PG_BASE, "implied", ISA_BASE, },
}
},
{ "INW", ISA_CE02, false, false, false,NULL,{
    { 0xe3, PG_BASE, "zp", ISA_BASE, },
}
},
{ "DEW", ISA_CE02, false, false, false,NULL,{
    { 0xc3, PG_BASE, "zp", ISA_BASE, },
}
},
{ "INZ", ISA_CE02, false, false, false,NULL,{
    { 0x1b, PG_BASE, "implied", ISA_BASE, },
}
},
{ "DEZ", ISA_CE02, false, false, false,NULL,{
    { 0x3b, PG_BASE, "implied", ISA_BASE, },
}
},
{ "ASW", ISA_CE02, false, false, false,NULL,{
    { 0xcb, PG_BASE, "abs", ISA_BASE, },
}
},
{ "ROW", ISA_CE02, false, false, false,NULL,{
    { 0xeb, PG_BASE, "abs", ISA_BASE, },
}
},
{ "LDZ", ISA_CE02, false, false, false,NULL,{
    { 0xa3, PG_BASE, "imm", ISA_BASE, },
    { 0xbb, PG_BASE, "absx", ISA_BASE, },
    { 0xab, PG_BASE, "abs", ISA_BASE, },
}
},
{ "PHW", ISA_CE02, false, false, false,NULL,{
    { 0xf4, PG_BASE, "imm2", ISA_BASE, },
    { 0xfc, PG_BASE, "abs", ISA_BASE, },
}
},
{ "TAZ", ISA_CE02, false, false, false,NULL,{
    { 0x4b, PG_BASE, "implied", ISA_BASE, },
}
},
{ "TZA", ISA_CE02, false, false, false,NULL,{
    { 0x6b, PG_BASE, "implied", ISA_BASE, },
}
},
{ "PHZ", ISA_CE02, false, false, false,NULL,{
    { 0xdb, PG_BASE, "implied", ISA_BASE, },
}
},
{ "PLZ", ISA_CE02, false, false, false,NULL,{
    { 0xfb, PG_BASE, "implied", ISA_BASE, },
}
},
{ "REP", ISA_816, false, false, false,NULL,{
    { 0xc2, PG_BASE, "imm", ISA_BASE, },
}
},
{ "SEP", ISA_816, false, false, false,NULL,{
    { 0xe2, PG_BASE, "imm", ISA_BASE, },
}
},
{ "STP", ISA_816, false, false, false,NULL,{
    { 0xdb, PG_BASE, "implied", ISA_BASE, },
}
},
{ "WAI", ISA_816, false, false, false,NULL,{
    { 0xcb, PG_BASE, "implied", ISA_BASE, },
}
},
{ "XCE", ISA_816, false, false, false,NULL,{
    { 0xfb, PG_BASE, "implied", ISA_BASE, },
}
},
{ "XBA", ISA_816, false, false, false,NULL,{
    { 0xeb, PG_BASE, "implied", ISA_BASE, },
}
},
{ "WDM", ISA_816, false, false, false,NULL,{
    { 0x42, PG_BASE, "implied", ISA_BASE, },
}
},
{ "TDC", ISA_816, false, false, false,NULL,{
    { 0x7b, PG_BASE, "implied", ISA_BASE, },
}
},
{ "TCD", ISA_816, false, false, false,NULL,{
    { 0x5b, PG_BASE, "implied", ISA_BASE, },
}
},
{ "TSC", ISA_816, false, false, false,NULL,{
    { 0x3b, PG_BASE, "implied", ISA_BASE, },
}
},
{ "TCS", ISA_816, false, false, false,NULL,{
    { 0x1b, PG_BASE, "implied", ISA_BASE, },
}
},
{ "TXY", ISA_816, false, false, false,NULL,{
    { 0x9b, PG_BASE, "implied", ISA_BASE, },
}
},
{ "TYX", ISA_816, false, false, false,NULL,{
    { 0xbb, PG_BASE, "implied", ISA_BASE, },
}
},
{ "PEI", ISA_816, false, false, false,NULL,{
    { 0xd4, PG_BASE, "zp", ISA_BASE, },
}
},
{ "PEA", ISA_816, false, false, false,NULL,{
    { 0xf4, PG_BASE, "imm2", ISA_BASE, },
}
},
{ "PER", ISA_816, false, false, false,NULL,{
    { 0x62, PG_BASE, "relw", ISA_816CE02, },
}
},
{ "PLB", ISA_816, false, false, false,NULL,{
    { 0xab, PG_BASE, "implied", ISA_BASE, },
}
},
{ "PHB", ISA_816, false, false, false,NULL,{
    { 0x8b, PG_BASE, "implied", ISA_BASE, },
}
},
{ "PLD", ISA_816, false, false, false,NULL,{
    { 0x2b, PG_BASE, "implied", ISA_BASE, },
}
},
{ "PHD", ISA_816, false, false, false,NULL,{
    { 0x0b, PG_BASE, "implied", ISA_BASE, },
}
},
{ "PHK", ISA_816, false, false, false,NULL,{
    { 0x4b, PG_BASE, "implied", ISA_BASE, },
}
},
{ "RTL", ISA_816, false, false, false,NULL,{
    { 0x6b, PG_BASE, "implied", ISA_BASE, },
}
},
{ "COP", ISA_816, false, false, false,NULL,{
    { 0x02, PG_BASE, "imm", ISA_BASE, },
}
},
{ "MVN", ISA_816, false, false, false,NULL,{
    { 0x54, PG_BASE, "dimm", ISA_816, },
}
},
{ "MVP", ISA_816, false, false, false,NULL,{
    { 0x44, PG_BASE, "dimm", ISA_816, },
}
},
};

