clear all;
load('../data/GNSSaidedINS_data2d.mat');

% initial value;
X = [data2d.GNSS.pos_EN(:,1);0;0;0];
P = eye(5,5);
P(5,5) = 0.1;
it_imu = 0;
it_gps = 0;
X_list = X;
for id_t_imu = 1:length(data2d.IMU.t)
    t_imu = data2d.IMU.t(id_t_imu);
    %% predict;
    it_imu = it_imu + 1;
    delta_t = 0.01;
    aL = data2d.IMU.acc(:, it_imu);
    theta = X(5);
    delta_yaw = data2d.IMU.gyro(1,it_imu)*delta_t;
    % F, Bu; Q;
    F = eye(5,5);
    F(1, 3) = delta_t;
    F(2,4) = delta_t;
    Bu = zeros(5,1);
    Bu(1:2, 1) = 0.5*delta_t^2*to_R2d(theta)*aL;
    Bu(3:4, 1) = delta_t*to_R2d(theta)*aL;
    Bu(5,1) = delta_yaw;
    Q  = 0.001*eye(5,5);
    X_bar = F*X + Bu;
    P_bar = F*P*F' + Q;
    
    %% update
    % check if the t equals the gps 
    if (it_gps + 1 <= length(data2d.GNSS.t)) && (t_imu == data2d.GNSS.t(it_gps + 1))
        it_gps
        it_gps = it_gps + 1;
        H = eye(2,5);
        R = 4*eye(2,2);
        z = data2d.GNSS.pos_EN(:,it_gps);
        y = z - H*X_bar;
        K = P_bar*H'*inv(H*P_bar*H' + R);
        X = X_bar + K*y;
        P = (eye(5,5) - K*H)*P_bar;
        X_list = cat(2, X_list, X);
    else
        X = X_bar;
        P = P_bar;
    end
    
end

scatter(X_list(1,:), X_list(2,:));

