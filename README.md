# 32-bit RISC-V Integer Multiprocessor

We designed a multi-cycle RISC-V processor that implements all of the instructions in the base RV32I instruction set except for ecall, ebreak, csrrw, csrrs, csrrc, csrrwi, csrrsi, and csrrci. We adapted the Patterson & Hennesy and Harris & Harris multicycle processor architectures to flow through the Instruction Fetch, Instruction Decode/Register Fetch, Execute/Address Calculation, Memory Access, and Writeback phases and restructured the immediate block for RISC-V to include the I-type, S-type, B-type, U-type, and J-type immediate formats. 
