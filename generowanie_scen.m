SOFAstart;
hrtf = SOFAload('C:/Users/User/Desktop/SOFA API/HRTFs/ARI/hrtf_nh130.sofa');

path = 'C:/Users/User/Desktop/surowe nagrania';
save_path = 'C:/Users/User/Desktop/wygenerowane sceny';
folders = dir(path);
values_path = 'C:/Users/User/Desktop/wygenerowane sceny/values';

front_values = [];
back_values = [];
front_scene = [];
back_scene = [];

pom = 1;
for i = 3 : length(folders)
  
  front_values = [];
  back_values = [];
  
  fprintf('Folder #%d = %s\n', pom, folders(i).name);
  audio_path = [path "/" folders(i).name];
  audio_files = dir(audio_path);
  pom_2 = 1;
  for j = 3 : length(audio_files)
    %%Wczytanie plików audio
    
    fprintf('Music #%d = %s\n', pom_2, audio_files(j).name);
    aduioread_path = [audio_path "/" audio_files(j).name];
    [audio_file, fs] = audioread(aduioread_path);
    
    if(fs != 48000)
      fs = 48000;
    endif
    
    %%Generowanie losowej wartoœci dla scen
    rand_front = randi([-30 30]);
    if(rand_front >= 0)
      rand_back = 180 - rand_front;
    else
      a = 180 + rand_front;
      rand_back = a*(-1);
    endif
    %%Tworzenie sceny przedniej
    ele=[0];
    azi1_front=[rand_front];
    out_front = SOFAspat(audio_file,hrtf,azi1_front,ele);
    
    if (pom_2 == 1)
      front_scene = out_front;
    else
      front_scene = (front_scene + out_front);
    endif  
    
    front_values(pom_2) = rand_front;
    
    %%Tworzenie sceny tylnej
    
    azil_back = [rand_back];
    out_back = SOFAspat(audio_file,hrtf,azil_back,ele);
    
    if (pom_2 == 1)
      back_scene = out_back;
    else
      back_scene = (back_scene + out_back);
    endif  
    
    back_values(pom_2) = rand_back;
    
    pom_2 ++;
  endfor
  
  %%fs = 48000;
  
  %%Zapisanie stworzonych scen
  Lmax = max(abs(front_scene(:,1)));
  Rmax = max(abs(front_scene(:,2)));
  LRmax = max(Lmax,Rmax);
  front_scene_save = (0.7*front_scene)/LRmax;
  
  
  [m,n] = size(front_scene_save);
  dt=1/fs;
  time = dt*(0:m-1);
  idx = (time>=0.5) & (time<=7.5);
  front_scene_save = front_scene_save(idx,:);
  
  save_front_aduio_path = [save_path '/front_scene_' folders(i).name '.wav'];
  audiowrite(save_front_aduio_path, front_scene_save, fs);
  
  Lmax_b = max(abs(back_scene(:,1)));
  Rmax_b = max(abs(back_scene(:,2)));
  LRmax_b = max(Lmax_b,Rmax_b);
  back_scene_save = (0.7*back_scene)/LRmax_b;
  
  [mb, nb] = size(back_scene_save);
  dt_b = 1/fs;
  time_b = dt_b*(0:mb-1);
  idx_b = (time_b>=0.5) & (time_b<=7.5);
  back_scene_save = back_scene_save(idx_b,:);
  
  save_back_audio_path = [save_path '/back_scene_' folders(i).name '.wav'];
  audiowrite(save_back_audio_path, back_scene_save, fs);
  
  %%Zapisanie wylosowanych wartoœci do pliku
  save_front_values_path = [values_path '/front_scene_' folders(i).name '.txt'];
  filevalues_front = fopen(save_front_values_path,"w");
  for x = 1 : length(front_values)
    fprintf(filevalues_front, "front source %d: %d \n",x, front_values(x));
  endfor
  fclose(filevalues_front);
  
  save_back_values_path = [values_path '/back_scene_' folders(i).name '.txt'];
  filevalues_back = fopen(save_back_values_path,"w");
  for y = 1 : length(back_values)
    fprintf(filevalues_back, "back source %d: %d \n",y, back_values(y));
  endfor
  fclose(filevalues_back);
  
  pom ++;
endfor

disp('stop');