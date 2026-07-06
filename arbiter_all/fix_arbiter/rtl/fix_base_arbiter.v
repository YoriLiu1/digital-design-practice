// ============================================================================
// 固定基优先级仲裁器 - Fixed-Base Priority Arbiter
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 功能: 从 base 指向的位置开始, 按低到高的顺序找到第一个有效请求并授权
//
// 工作原理:
//   将 req 复制拼接为 double_req = {req, req} (实现 wrap-around),
//   再用位运算 "double_req & ~(double_req - base)" 找到从 base 起
//   第一个为 1 的 bit, 折叠回 CHANNEL 位宽即得 grant。
//
// 参数:
//   CHANNEL — 请求通道数 (默认 4)
//
// 输入:
//   req  [CHANNEL-1:0] — 请求信号
//   base [CHANNEL-1:0] — 优先级起点 (one-hot), base[i]=1 表示从 i 开始
//
// 输出:
//   grant [CHANNEL-1:0] — 授权信号 (one-hot)
//
// 优先级规则 (base[i]=1 时):
//   优先级从高到低: req[i] > req[i-1] > ... > req[0] > req[N-1] > ... > req[i+1]
//
// 示例 (CHANNEL=4, base=4'b0100):
//   优先级: req[1] > req[0] > req[3] > req[2]
//
// 示例 (CHANNEL=4, req=4'b1011, base=4'b0001):
//   double_req = 8'b1011_1011
//   double_req - base = 8'b1011_1010
//   ~(double_req - base) = 8'b0100_0101
//   double_gnt = 8'b1011_1011 & 8'b0100_0101 = 8'b0001_0001
//   grant = 4'b0001 | 4'b0001 = 4'b0001  → 授权 req[0]
// ============================================================================

module fix_base_arbiter #(
    parameter CHANNEL = 4              // 通道数
)(
    input           [CHANNEL-1 : 0]   req,    // 请求 (多 bit 可同时有效)
    input           [CHANNEL-1 : 0]   base,   // 优先级起点 (one-hot)
    output  wire    [CHANNEL-1 : 0]   grant   // 授权输出 (one-hot)
);

    // ---- 将 req 复制拼接, 实现环形搜索 ----
    //     高位 = req, 低位 = req, 便于从 base 起跨边界查找
    wire [2 * CHANNEL - 1 : 0] double_req = {req, req};

    // ---- 核心算法: 找到从 base 位置开始的第一个 '1' ----
    //     位运算技巧: X & ~(X - base) 提取 X 中从 base 偏移起的第一个 set bit
    //     (X - base) 将 base 指向的第一个 '1' 及以下位全部翻转,
    //     取反后与 X 相与, 即得到第一个 '1' 的位置
    wire [2 * CHANNEL - 1 : 0] double_gnt = double_req & ~(double_req - base);

    // ---- 将双倍位宽结果折叠回 CHANNEL 位 ----
    //     高位部分 OR 低位部分, 因为请求可能跨越复制边界
    assign grant = double_gnt[CHANNEL - 1 : 0]
                 | double_gnt[2 * CHANNEL - 1 : CHANNEL];

endmodule
