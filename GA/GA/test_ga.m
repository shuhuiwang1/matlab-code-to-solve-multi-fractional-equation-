clear; 
close all;
[best_fitness, elite, generation, last_generation] = my_ga(3, 'my_fitness', 100, 50, 0.1, 10000, 1.0e-6);



% disp(best_fitness(9990:10000,:));
% disp(elite(9990:10000,:))

% �������Ǻ��ʵ����
disp(last_generation); 
i_begin = last_generation - 9;
disp(best_fitness(i_begin:last_generation,:));
% ��eliteֵת��Ϊ���ⷶΧ��
my_elite = elite(i_begin:last_generation,:);
my_elite = 2 * (my_elite - 0.5);
disp(my_elite);

% �����Ӧ�ȵ��ݻ����
figure
loglog(1:generation, best_fitness(1:generation), 'linewidth',2)
xlabel('Generation','fontsize',15);
ylabel('Best Fitness','fontsize',15);
set(gca,'fontsize',15,'ticklength',get(gca,'ticklength')*2);

% ���Ž���ݻ����
figure
semilogx(1 : generation, 2 * elite(1 : generation, :) - 1)
xlabel('Generation','fontsize',15);
ylabel('Best Solution','fontsize',15);
set(gca,'fontsize',15,'ticklength',get(gca,'ticklength')*2);
