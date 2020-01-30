% Plot learning curve from Excel loss/accuracy training data
% 8-14-19
% George Liu
% Dependencies: none

[file,path] = uigetfile('*.xlsx');
A = readmatrix(fullfile(path, file));

train_acc = A(1:5:end, 5);
val_acc = A(2:5:end, 5);
train_loss = A(1:5:end, 3);
val_loss = A(2:5:end, 3);

%%
NUM_CLASSES = 12;
epoch = 5:93;

% Plot loss
figure
plot(epoch, train_loss, 'LineWidth', 1, 'Color', 'b')
hold on
plot(epoch, val_loss, 'LineWidth', 1, 'Color', 'r')
randomguess_loss = log(NUM_CLASSES);
yline(randomguess_loss, '-.g');
hold off

title('Learning curve')
xlabel('Epoch')
ylabel('Cross entropy loss')
legend('Train', 'Val', 'Random guess')

% Plot acc
figure
plot(epoch, train_acc, 'LineWidth', 1, 'Color', 'b')
hold on
plot(epoch, val_acc, 'LineWidth', 1, 'Color', 'r')
randomguess_acc = 1/NUM_CLASSES;
yline(randomguess_acc, '-.g');
hold off

title('Learning curve')
xlabel('Epoch')
ylabel('Accuracy')
legend('Train', 'Val', 'Random guess')



