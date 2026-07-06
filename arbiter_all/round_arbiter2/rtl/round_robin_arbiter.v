// ============================================================================
// 轮询仲裁器 - Round-Robin Arbiter (prefix-OR mask 法)
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 功能: 多通道公平轮询调度, 输出当前被授权通道的 binary index
//
// 算法原理 (mask-based):
//   与减法取反法不同, 此版本使用"优先级屏蔽"策略:
//   1. req_power — 优先级寄存器, 初始全 1 (所有通道平等)
//   2. req_after_power = queue_i & req_power — 屏蔽已被调度的通道
//   3. old_mask  — prefix-OR: 当前通道及更低通道的 OR, 用于构建下次屏蔽字
//   4. old_grant — ~old_mask & req_after_power, 找屏蔽字中首个 set bit
//   5. 若 old_grant 无有效位, 则退回到 new_grant (从所有请求中重新开始)
//   6. 每次 sche_en 有效时更新 req_power ← old_mask (或 new_mask)
//
// 与 fix_base_arbiter 方案的对比:
//   - 减法取反法: 核心是 X & ~(X - base), 依赖加法器的借位链
//   - mask 法:     核心是 prefix-OR 链, 两种方案可综合性相当
//   - mask 法输出 binary index, 减法法输出 one-hot grant
//
// 参数:
//   DEEP_NUM — 最大通道数 (默认 8)
//
// 端口:
//   clk       — 时钟
//   rst_n     — 复位 (低有效)
//   queue_i   — 请求队列 (bit[i]=1 表示通道 i 请求服务)
//   sche_en   — 调度使能 (高有效, 每次使能推进一轮仲裁)
//   pointer_o — 当前授权通道的 binary index ($clog2 位宽)
// ============================================================================

module round_robin_arbiter #(
    parameter DEEP_NUM = 8                          // 通道数
)(
    input  wire                            clk,      // 时钟
    input  wire                            rst_n,    // 复位 (低有效)
    input  wire [DEEP_NUM        -1 : 0]   queue_i,  // 请求队列
    input  wire                            sche_en,  // 调度使能
    output wire [$clog2(DEEP_NUM) - 1 : 0] pointer_o // 授权通道 binary index
);

    // ---- 优先级寄存器: 初始全 1, 调度后屏蔽已授权通道及更低位 ----
    reg  [DEEP_NUM - 1 : 0] req_power;
    wire [DEEP_NUM - 1 : 0] req_after_power = queue_i & req_power;

    // ---- old_mask: prefix-OR of req_after_power ----
    //     用于在"上次优先级屏蔽后仍有请求"时构建下次屏蔽字
    //     递推: old_mask[i] = old_mask[i-1] | req_after_power[i-1]
    //           old_mask[0]   = 1'b0
    wire [DEEP_NUM - 1 : 0] old_mask =
        {req_after_power[DEEP_NUM - 2 : 0] | old_mask[DEEP_NUM - 2 : 0],
         1'b0};

    // ---- new_mask: prefix-OR of 原始 queue_i ----
    //     用于"req_after_power 为空, 需要从原始请求重新开始"的情况
    wire [DEEP_NUM - 1 : 0] new_mask =
        {queue_i[DEEP_NUM - 2 : 0] | new_mask[DEEP_NUM - 2 : 0],
         1'b0};

    // ---- 是否有被屏蔽字过滤后仍然存活的请求 ----
    wire old_grant_work = (|req_after_power);

    // ---- Grant 生成 ----
    //     old_grant: 在 req_after_power 中找第一个 set bit
    //     new_grant: 在原始 queue_i 中找第一个 set bit (fallback)
    wire [DEEP_NUM - 1 : 0] old_grant = ~old_mask & req_after_power;
    wire [DEEP_NUM - 1 : 0] new_grant = ~new_mask & queue_i;
    wire [DEEP_NUM - 1 : 0] grant     = old_grant_work ? old_grant : new_grant;

    // ---- One-hot → Binary index 编码 ----
    function automatic [$clog2(DEEP_NUM) - 1 : 0] onehot_to_index;
        input [DEEP_NUM - 1 : 0] onehot;
        integer i;
        begin
            onehot_to_index = {$clog2(DEEP_NUM){1'b0}};
            for (i = 0; i < DEEP_NUM; i = i + 1) begin
                if (onehot[i])
                    onehot_to_index = i;
            end
        end
    endfunction

    assign pointer_o = (|queue_i) ? onehot_to_index(grant)
                                  : {$clog2(DEEP_NUM){1'b0}};

    // ---- req_power 更新 ----
    //     复位:  全 1 (所有通道同等优先级)
    //     sche_en 有效时:
    //       若 old_grant 产生有效位 → req_power = old_mask (屏蔽已授权及更低位)
    //       否则有请求但需重开一轮   → req_power = new_mask (从原始请求重建)
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            req_power <= {DEEP_NUM{1'b1}};
        end
        else if (sche_en) begin
            if (old_grant_work)
                req_power <= old_mask;
            else if (|queue_i)
                req_power <= new_mask;
        end
    end

endmodule
