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
