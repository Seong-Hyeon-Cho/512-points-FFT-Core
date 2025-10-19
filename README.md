# 512-point FFT 코어

## 프로젝트 개요
- 이 프로젝트는 MATLAB을 통해 512-point 고정소수점 FFT를 검증하고 radix - ![formula](https://latex.codecogs.com/svg.image?2^2) FFT를 파이프라인 구조로 설계합니다. 
- 설계한 모듈을 RTL level과 GATE level에서의 검증을 통해 타이밍을 확인하고 ASIC 성능을 확인합니다.
- 검증된 모듈을 FPGA 보드에서 합성한 후 ASIC에서와의 성능을 비교합니다.

|구분|이름|
|----|----|
|사용언어|System Verilog|
|tool| Xilinx Vivado, Synopsys VCS, Synopsys Verdi|

### radix - ![formula](https://latex.codecogs.com/svg.image?2^2) FFT
 - radix-2 두 단계를 한 묶음으로 만들어 radix-4와 비슷한 효율
 - 한 스테이지 안에서 2개의 radix-2 butterfly를 연달아 수행(+/- 합차 -> twiddle 곱 -> 다시 +/- 합차)<br>
 [예시 8-point radix - ![formula](https://latex.codecogs.com/svg.image?2^2) 구조]<br>
<img width="1374" height="1024" alt="Image" src="https://github.com/user-attachments/assets/d15fefdb-5fe0-43fc-b8b3-dd5ff66ac3f0" /><br><br>

[예시 256-point radix - ![formula](https://latex.codecogs.com/svg.image?2^2) SDF Pipeline FFT Architecture]<br>
<img width="1205" height="378" alt="Image" src="https://github.com/user-attachments/assets/af342dda-28ea-423d-a06a-b8323a55d5ba" /><br>
- SDF(streaming) 파이프라인 구조  
    ※ SDF(Single-path Delay Feedback, 단일 경로 지연-피드백): 입력 스트림을 한 줄로 흘리면서, 스테이지마다 일부 샘플을 지연 라인에 저장해 두었다가 다음에 들어오는 샘플과 다시 합/차를 만들도록 피드백시키는 구조<br>
    [장점]: HW 자원(곱셈기/메모리) 절약, 완전 스트리밍(1 sample/clk 가능), 간단한 인터페이스<br>
    [단점]: 제어(state/카운터) 필요, 출력 직전 마지막에 재정렬 필요<br>

### 설계

[RTL설계 블록도]
<br><img width="1666" height="1207" alt="Image" src="https://github.com/user-attachments/assets/07351bf3-6fcf-4270-aa72-67bf2b1d98c8" /><br>
- 한 클럭에 16개의 샘플을 처리합니다.
- 각 stage는 입력되는 총 샘플의 절반가량의 딜레이 버퍼 크기를 가지고 있습니다.
- 각 stage마다 처리하는 총 샘플링 개수가 절반씩 줄어듭니다.<br><br>

#### CBFP
Convergent Block Floating-Point 
- 데이터 표현/스케일 방식으로서의 BFP(Block Floating-Point) — “블록” 안 모든 샘플이 하나의 공통 지수(exponent)를 공유하고, 양자화(반올림) 규칙으로서의 Convergent rounding(= round-to-nearest-even, 짝수 반올림) 을 동시에 채택한 고정소수점-친화 설계
“공통 지수 BFP + 편향이 거의 없는 반올림” 

- 성능 관점 요약
    - BFP(공통 지수)로 오버플로 억제 + 리소스/전력 절감
    - Convergent(짝수 반올림)으로 편향 최소화, 누적 처리(FFT, 필터 체인)에서 DC/왜곡 누적 억제
    - SQNR은 보통 truncation 대비 수 dB 개선(정확치는 비트폭·블록크기·분포에 의존)

### 성능 확인
#### ASIC 성능 점검
500MHz clock 기준<br>
[시뮬레이션]<br>
<img width="993" height="840" alt="Image" src="https://github.com/user-attachments/assets/4e25948a-1424-4967-b5af-6caf271850ba" /><br><br>
[성능 결과]<br>
<img width="1853" height="1043" alt="Image" src="https://github.com/user-attachments/assets/549cbaa1-2f10-4e57-b982-34096e7a8105" /><br><br>
<img width="1853" height="1025" alt="Image" src="https://github.com/user-attachments/assets/6009c809-1083-4417-a02f-5eb65f85f20c" /><br>

#### FPGA 성능 점검
100MHz clock 기준<br>
[아키텍처 구성]<br>
<img width="1747" height="847" alt="Image" src="https://github.com/user-attachments/assets/81c350d8-6288-47b8-96d9-c1840ea19e7c" /><br><br>
[시뮬레이션]<br>
<img width="2001" height="875" alt="Image" src="https://github.com/user-attachments/assets/bda07487-ca3a-4f39-b5d3-64033880ea62" /><br>
<br>[성능 결과]<br>
<img width="1701" height="639" alt="Image" src="https://github.com/user-attachments/assets/4743ae4b-2ad1-4d54-98c9-ecc6373b1878" /><br><br>
<img width="1581" height="693" alt="Image" src="https://github.com/user-attachments/assets/86818301-13aa-4980-9862-6ef9c40eae97" /><br>
