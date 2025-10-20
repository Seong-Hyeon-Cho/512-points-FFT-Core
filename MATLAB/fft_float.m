% Added on 2025/07/01 by jihan 
function [fft_out, module2_out] = fft_float(fft_mode, fft_in)

 shift = 0;
 SIM_FIX = 0; % 0: float, 1: fixed

 if (fft_mode==1) % fft
	din = fft_in;
 else % ifft
	din = conj(fft_in);
 end

 fac8_0 = [1, 1, 1, -j];
 fac8_1 = [1, 1, 1, -j, 1, 0.7071-0.7071j, 1, -0.7071-0.7071j];

 %-----------------------------------------------------------------------------
 % Module 0
 %-----------------------------------------------------------------------------
 % step0_0
 bfly00_out0 = din(1:256) + din(257:512);
 bfly00_out1 = din(1:256) - din(257:512);

 bfly00_tmp = [bfly00_out0, bfly00_out1];

 for nn=1:512
	bfly00(nn) = bfly00_tmp(nn)*fac8_0(ceil(nn/128));
 end

 % step0_1
 for kk=1:2
  for nn=1:128
	bfly01_tmp((kk-1)*256+nn) = bfly00((kk-1)*256+nn) + bfly00((kk-1)*256+128+nn);
	bfly01_tmp((kk-1)*256+128+nn) = bfly00((kk-1)*256+nn) - bfly00((kk-1)*256+128+nn);
  end
 end


 for nn=1:512
	bfly01(nn) = bfly01_tmp(nn)*fac8_1(ceil(nn/64));
 end

 % step0_2
 for kk=1:4
  for nn=1:64
	bfly02_tmp((kk-1)*128+nn) = bfly01((kk-1)*128+nn) + bfly01((kk-1)*128+64+nn);
	bfly02_tmp((kk-1)*128+64+nn) = bfly01((kk-1)*128+nn) - bfly01((kk-1)*128+64+nn);
  end
 end

 % Data rearrangement
 K3 = [0, 4, 2, 6, 1, 5, 3, 7];

 for kk=1:8
  for nn=1:64
	twf_m0((kk-1)*64+nn) = exp(-j*2*pi*(nn-1)*(K3(kk))/512);
  end
 end

 for nn=1:512
	bfly02(nn) = bfly02_tmp(nn)*twf_m0(nn);
 end

 %-----------------------------------------------------------------------------
 % Module 1
 %-----------------------------------------------------------------------------
 % step1_0
 for kk=1:8
  for nn=1:32
	bfly10_tmp((kk-1)*64+nn) = bfly02((kk-1)*64+nn) + bfly02((kk-1)*64+32+nn);
	bfly10_tmp((kk-1)*64+32+nn) = bfly02((kk-1)*64+nn) - bfly02((kk-1)*64+32+nn);
  end
 end

 for kk=1:8
  for nn=1:64
	bfly10((kk-1)*64+nn) = bfly10_tmp((kk-1)*64+nn)*fac8_0(ceil(nn/16));
  end
 end

 % step1_1
 for kk=1:16
  for nn=1:16
	bfly11_tmp((kk-1)*32+nn) = bfly10((kk-1)*32+nn) + bfly10((kk-1)*32+16+nn);
	bfly11_tmp((kk-1)*32+16+nn) = bfly10((kk-1)*32+nn) - bfly10((kk-1)*32+16+nn);
  end
 end

 for kk=1:8
  for nn=1:64
	bfly11((kk-1)*64+nn) = bfly11_tmp((kk-1)*64+nn)*fac8_1(ceil(nn/8));
  end
 end

 % step1_2
 for kk=1:32
  for nn=1:8
	bfly12_tmp((kk-1)*16+nn) = bfly11((kk-1)*16+nn) + bfly11((kk-1)*16+8+nn);
	bfly12_tmp((kk-1)*16+8+nn) = bfly11((kk-1)*16+nn) - bfly11((kk-1)*16+8+nn);
  end
 end

 % Data rearrangement
 K2 = [0, 4, 2, 6, 1, 5, 3, 7];

 for kk=1:8
  for nn=1:8
	twf_m1((kk-1)*8+nn) = exp(-j*2*pi*(nn-1)*(K2(kk))/64);
  end
 end

 for kk=1:8
  for nn=1:64
	bfly12((kk-1)*64+nn) = bfly12_tmp((kk-1)*64+nn)*twf_m1(nn);
  end
 end

 %-----------------------------------------------------------------------------
 % Module 2
 %-----------------------------------------------------------------------------
 % step2_0
 for kk=1:64
  for nn=1:4
	bfly20_tmp((kk-1)*8+nn) = bfly12((kk-1)*8+nn) + bfly12((kk-1)*8+4+nn);
	bfly20_tmp((kk-1)*8+4+nn) = bfly12((kk-1)*8+nn) - bfly12((kk-1)*8+4+nn);
  end
 end

 for kk=1:64
  for nn=1:8
	bfly20((kk-1)*8+nn) = bfly20_tmp((kk-1)*8+nn)*fac8_0(ceil(nn/2));
  end
 end

 % step2_1
 for kk=1:128
  for nn=1:2
	bfly21_tmp((kk-1)*4+nn) = bfly20((kk-1)*4+nn) + bfly20((kk-1)*4+2+nn);
	bfly21_tmp((kk-1)*4+2+nn) = bfly20((kk-1)*4+nn) - bfly20((kk-1)*4+2+nn);
  end
 end

 for kk=1:64
  for nn=1:8
	bfly21((kk-1)*8+nn) = bfly21_tmp((kk-1)*8+nn)*fac8_1(nn);
  end
 end

 % step2_2
 for kk=1:256
	bfly22_tmp((kk-1)*2+1) = bfly21((kk-1)*2+1) + bfly21((kk-1)*2+2);
	bfly22_tmp((kk-1)*2+2) = bfly21((kk-1)*2+1) - bfly21((kk-1)*2+2);
 end

 bfly22 = bfly22_tmp;

 %-----------------------------------------------------------------------------
 % Index 
 %-----------------------------------------------------------------------------
 fp=fopen('reorder_index.txt','w');
 for jj=1:512
	%kk = bitget(jj-1,9)*(2^0) + bitget(jj-1,8)*(2^1) + bitget(jj-1,7)*(2^2) + bitget(jj-1,6)*(2^3) + bitget(jj-1,5)*(2^4) + bitget(jj-1,4)*(2^5) + bitget(jj-1,3)*(2^6) + bitget(jj-1,2)*(2^7) + bitget(jj-1,1)*(2^8);
	kk = bitget(jj-1,9)*1 + bitget(jj-1,8)*2 + bitget(jj-1,7)*4 + bitget(jj-1,6)*8 + bitget(jj-1,5)*16 + bitget(jj-1,4)*32 + bitget(jj-1,3)*64 + bitget(jj-1,2)*128 + bitget(jj-1,1)*256;
	dout(kk+1) = bfly22(jj); % With reorder
	fprintf(fp, 'jj=%d, kk=%d, dout(%d)=%f+j%f\n',jj, kk,(kk+1),real(dout(kk+1)),imag(dout(kk+1)));
 end
 fclose(fp);

 if (fft_mode==1) % fft
	fft_out = dout;
	module2_out = bfly22;
 else % ifft
	fft_out = conj(dout)/512; 
	module2_out = conj(bfly22)/512;

 end

end
