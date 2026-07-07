# Digital Design Practice

数字 IC 设计练习集, 包含常见数字电路模块的 RTL 实现、testbench 及 Makefile 仿真环境。

## 环境要求

| 工具 | 用途 |
|------|------|
| [Icarus Verilog](http://iverilog.icarus.com/) (iverilog + vvp) | 编译与仿真 |
| [GTKWave](http://gtkwave.sourceforge.net/) | 波形查看 |

## 快速开始

每个模块目录下都有 `sim/` 文件夹, 内含 Makefile:

```bash
cd <模块名>/sim
make          # 编译 + 仿真
make wave     # 用 GTKWave 打开波形
make clean    # 清理仿真产物
```

---

## 模块列表

### 1. async_fifo — 异步 FIFO

| | |
|---|---|
| **文件** | [async_fifo/](async_fifo/) |
| **顶层** | `async_fifo_tb` |
| **描述** | 跨时钟域异步 FIFO, 支持可配置位宽/深度, 含 `almost_full` / `almost_empty` 水位线 |
| **技术点** | 格雷码指针、两级同步器、双时钟域 CDC |

### 2. Data_Packet_Detector — 数据包检测器

| | |
|---|---|
| **文件** | [Data_Packet_Detector/](Data_Packet_Detector/) |
| **顶层** | `tb_data` |
| **描述** | FSM 状态机检测数据包: 起始码 `0xFF00` + 数据段 (n<256 bytes) + 结束码 `0xFF01`, 输出字节计数 |
| **技术点** | 四状态 FSM (IDLE→WAIT_START→IN_DATA→WAIT_END)、pkt_err 异常处理 |

### 3. frame_head_detector — 帧头检测器

| | |
|---|---|
| **文件** | [frame_head_detector/](frame_head_detector/) |
| **顶层** | `tb_frame_head` |
| **描述** | 检测连续 3 次 `8'h23`, 输出一拍 `head_vld` 脉冲; 中间被打断则重新计数 |
| **技术点** | 连续模式匹配、next_state 组合逻辑、frame_vld 门控 |

### 4. arbiter_all/arbiter — 加权仲裁器

| | |
|---|---|
| **文件** | [arbiter_all/arbiter/](arbiter_all/arbiter/) |
| **顶层** | `tb_arbiter` |
| **描述** | 两个请求源 A/B 之间按可配置权重比 (`A_ratio : B_ratio`) 循环仲裁 |
| **技术点** | 加权轮询、计数器循环复位 |

### 5. arbiter_all/fix_arbiter — 固定基优先级仲裁器

| | |
|---|---|
| **文件** | [arbiter_all/fix_arbiter/](arbiter_all/fix_arbiter/) |
| **顶层** | `tb_fix_arbiter` |
| **描述** | 从 base 位置开始寻找第一个有效请求并授权 (one-hot), 纯组合逻辑 |
| **算法** | `X & ~(X - base)` 减法取反法 |
| **技术点** | 位运算优先级编码、无时钟组合逻辑 |

### 6. arbiter_all/round_arbiter1 — 轮询仲裁器 (减法法)

| | |
|---|---|
| **文件** | [arbiter_all/round_arbiter1/](arbiter_all/round_arbiter1/) |
| **依赖** | `fix_base_arbiter` (arbiter_all/fix_arbiter) |
| **顶层** | `tb_round_arbiter` |
| **描述** | 基于 fix_base_arbiter 的公平轮询: 每次授权后将 grant 左移一位作为下次 base |
| **技术点** | 模块复用、环形旋转指针、one-hot grant 输出 |

### 7. arbiter_all/round_arbiter2 — 轮询仲裁器 (mask 法)

| | |
|---|---|
| **文件** | [arbiter_all/round_arbiter2/](arbiter_all/round_arbiter2/) |
| **顶层** | `tb_round_arbiter` |
| **描述** | 使用 prefix-OR mask 的轮询仲裁器: `req_power` 屏蔽已授权通道, `old_mask`/`new_mask` 构建下次优先级 |
| **输出** | binary index (`pointer_o`), 非 one-hot |
| **技术点** | prefix-OR 链、one-hot→binary 编码函数、`sche_en` 调度使能 |

### 8. divide_3 — 占空比 50% 三分频电路

| | |
|---|---|
| **文件** | [divide_3/](divide_3/) |
| **顶层** | `tb_div3` |
| **描述** | 输入时钟 3 分频, 输出严格 50% 占空比: 上升沿+下降沿双沿触发, OR 组合获得 1.5 拍高电平 |
| **技术点** | posedge/negedge 混用、模 3 计数器、占空比控制 |

### 9. Serial2Parallel — 串并转换 (6-bit)

| | |
|---|---|
| **文件** | [Serial2Parallel/](Serial2Parallel/) |
| **顶层** | `tb_Serial2Parallel` |
| **描述** | 6 拍串行输入 → 1 拍 6-bit 并行输出 (LSB first), 带 valid-ready 上下游握手和反压 |
| **技术点** | valid-ready 握手协议、backpressure 反压、移位寄存器 |

### 10. edge_detect — 边缘检测

| | |
|---|---|
| **文件** | [edge_detect/](edge_detect/) |
| **顶层** | `tb_edge_detect` |
| **描述** | 打两拍 + XOR, 检测输入信号的上升沿/下降沿, 输出 1 拍脉冲 |
| **技术点** | 两级寄存器同步、XOR 边缘检测 |

### 11. seq_detector — 序列检测器 (FSM)

| | |
|---|---|
| **文件** | [seq_detector/](seq_detector/) |
| **顶层** | `tb_seq_detector` |
| **描述** | Moore 型 FSM 检测 "1101" 序列, 支持重叠匹配 |
| **技术点** | 状态机设计、重叠检测、三段式 FSM |

### 12. Parallel2Serial — 并串转换 (6-bit)

| | |
|---|---|
| **文件** | [Parallel2Serial/](Parallel2Serial/) |
| **顶层** | `tb_Parallel2Serial` |
| **描述** | 1 拍 6-bit 并行输入 → 6 拍串行输出 (LSB first), 带握手反压 |
| **技术点** | 移位输出、发送状态机、反压暂停 |

### 13. gray_counter — Gray 码计数器

| | |
|---|---|
| **文件** | [gray_counter/](gray_counter/) |
| **顶层** | `tb_gray_counter` |
| **描述** | 可配置位宽 Gray 码计数器, 同时输出 binary 和 gray |
| **技术点** | Binary↔Gray 转换 (`gray = bin ^ (bin>>1)`)、邻位单 bit 变化 |

### 14. sync_fifo — 同步 FIFO

| | |
|---|---|
| **文件** | [sync_fifo/](sync_fifo/) |
| **顶层** | `tb_sync_fifo` |
| **描述** | 单时钟域同步 FIFO, 寄存器输出, MSB 扩展法区分空满 |
| **技术点** | 读写指针管理、空满判断、寄存器输出 |

### 15. clock_mux — Glitch-Free 时钟切换

| | |
|---|---|
| **文件** | [clock_mux/](clock_mux/) |
| **顶层** | `tb_clock_mux` |
| **描述** | 两个时钟源之间无毛刺切换, 下降沿门控 + 跨域反馈 |
| **技术点** | 时钟门控、两级同步器、neg edge 切换防毛刺 |

### 16. pulse_sync — 脉冲同步器 (CDC)

| | |
|---|---|
| **文件** | [pulse_sync/](pulse_sync/) |
| **顶层** | `tb_pulse_sync` |
| **描述** | 将源时钟域单周期脉冲同步到目标时钟域 (toggle 法) |
| **技术点** | 脉冲→toggle→两级同步→边缘检测、跨时钟域 |

### 17. ping_pong — 乒乓 Buffer

| | |
|---|---|
| **文件** | [ping_pong/](ping_pong/) |
| **顶层** | `tb_ping_pong` |
| **描述** | 双缓冲无缝切换, 写满一块自动切换到另一块, 读写流水不中断 |
| **技术点** | 双 bank 管理、full_banks 计数、寄存器输出、反压

---

## 目录结构

```
digital-design-practice/
├── async_fifo/                   # 异步 FIFO
│   ├── rtl/async_fifo.v
│   ├── tb/async_fifo_tb.v
│   └── sim/Makefile
├── Data_Packet_Detector/         # 数据包检测器
│   ├── rtl/data.v
│   ├── tb/tb_data.v
│   └── sim/Makefile
├── frame_head_detector/          # 帧头检测器
│   ├── rtl/frame_head.v
│   ├── tb/tb_frame_head.v
│   └── sim/Makefile
├── divide_3/                     # 50% 占空比三分频
│   ├── rtl/div3.v
│   ├── tb/tb_div3.v
│   └── sim/Makefile
├── Serial2Parallel/              # 串并转换 (6-bit)
│   ├── rtl/Serial2Parallel.v
│   ├── tb/tb_Serial2Parallel.v
│   └── sim/Makefile
├── edge_detect/                  # 边缘检测
├── seq_detector/                 # 序列检测器 (1101)
├── Parallel2Serial/              # 并串转换 (6-bit)
├── gray_counter/                 # Gray 码计数器
├── sync_fifo/                    # 同步 FIFO
├── clock_mux/                    # Glitch-free 时钟切换
├── pulse_sync/                   # 脉冲同步器 (CDC)
├── ping_pong/                    # 乒乓 buffer
└── arbiter_all/                  # 仲裁器合集
    ├── arbiter/                  #   加权仲裁器
    ├── fix_arbiter/              #   固定基优先级仲裁器
    ├── round_arbiter1/           #   轮询仲裁器 (减法法)
    └── round_arbiter2/           #   轮询仲裁器 (mask 法)
```

---

## 轮询仲裁器对比

| | round_arbiter1 (减法法) | round_arbiter2 (mask 法) |
|---|---|---|
| 算法核心 | `X & ~(X - base)` | prefix-OR + req_power |
| 关键路径 | 1 次减法 + 取反 + AND | prefix-OR 链 + AND |
| 依赖 | fix_base_arbiter | 无 |
| 输出格式 | one-hot grant | binary index |
| 调度控制 | req 为 0 时自动暂停 | `sche_en` 显式使能 |
| 位宽 | ≤16 差别不大 | ≤16 差别不大 |

两种方案综合后可达到相似的时序和面积, 选择主要取决于输出格式偏好和复用需求。

## 仿真说明

所有 testbench 均使用 Icarus Verilog 的 VCD 格式 (`$dumpfile` / `$dumpvars`), 可直接用 GTKWave 打开波形。仿真产物 (`simv`, `*.vcd`) 已加入 `.gitignore`。
