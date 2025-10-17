# 512-point FFT 코어

## 프로젝트 개요
- 이 프로젝트는 MATHLAB을 통해 512-point 고정소수점 FFT를 검증하고 radix - ![formula](https://latex.codecogs.com/svg.image?2^2) FFT를 파이프라인 구조로 설계합니다. 
- 설계한 모듈을 RTL level과 GATE level에서의 검증을 통해 타이밍을 확인하고 ASIC 성능을 확인합니다.
- 검증된 모듈을 FPGA 보드에서 합성한 후 ASIC에서와의 성능을 비교합니다.

|구분|이름|
|----|----|
|사용언어|System Verilog|
|tool| Xilinx Vivado, Synopsys VCS, Synopsys Verdi|

### 설계 구성

#### radix - ![formula](https://latex.codecogs.com/svg.image?2^2) FFT
<img width="1374" height="1024" alt="Image" src="https://github.com/user-attachments/assets/d15fefdb-5fe0-43fc-b8b3-dd5ff66ac3f0" /><br>

<img width="1205" height="378" alt="Image" src="https://github.com/user-attachments/assets/af342dda-28ea-423d-a06a-b8323a55d5ba" /><br>

[RTL설계 블록도]<br>
<img width="1678" height="828" alt="Image" src="https://github.com/user-attachments/assets/132bbbb7-792b-4c5d-b5a2-e40b18d8c88d" /><br>

### ASIC 성능 점검
[성능 결과]<br>
<img width="1853" height="1043" alt="Image" src="https://github.com/user-attachments/assets/549cbaa1-2f10-4e57-b982-34096e7a8105" /><br><br>
<img width="1853" height="1025" alt="Image" src="https://github.com/user-attachments/assets/6009c809-1083-4417-a02f-5eb65f85f20c" /><br>

### FPGA 성능 점검
[아키텍처 구성]<br>
<img width="1747" height="847" alt="Image" src="https://github.com/user-attachments/assets/81c350d8-6288-47b8-96d9-c1840ea19e7c" /><br><br>
<br>[성능 결과]<br>
<img width="1701" height="639" alt="Image" src="https://github.com/user-attachments/assets/4743ae4b-2ad1-4d54-98c9-ecc6373b1878" /><br><br>
<img width="1581" height="693" alt="Image" src="https://github.com/user-attachments/assets/86818301-13aa-4980-9862-6ef9c40eae97" /><br>