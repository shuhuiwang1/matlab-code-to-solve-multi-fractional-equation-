function [best_fitness, elite, generation, last_generation] = my_ga( ...
    number_of_variables, ...    % the dimension of the parameters that we need to solve
    fitness_function, ...       % the fitness function for selecting the gene 
    population_size, ...        % the population 
    parent_number, ...          % the number of individuals lefting in every generation(每一代中保持不变的个体数目)
    mutation_rate, ...          % 变异概率
    maximal_generation, ...     % 最大演化代数（循环次数）
    minimal_cost ...            % 最小目标值（函数值越小，适应度越高）
)

%the accumulative probability 
cumulative_probabilities = cumsum((parent_number:-1:1) / sum(parent_number:-1:1)); 
%initialize the best fitness to 1 
best_fitness = ones(maximal_generation, 1);

%record the best solution for every generation 
elite = zeros(maximal_generation, number_of_variables);
cost=zeros(population_size,1);
child_number = population_size - parent_number; 

% population size is the number of individuals in the group and every row
% is one individual  
% number_of_variables: dimension of problem 
%% here is for initialisation 
population = rand(population_size, number_of_variables);

last_generation = 0; % end the loop when the generation=0


% begin the evolution 
for generation = 1 : maximal_generation 
    
    % feval put the varibles into the designed function 
    for i=1:population_size 
        cost(i) = feval(fitness_function, population(i,:));
    end 
    % make the rank of the cost and their index 
    [cost, index] = sort(cost); 

    %choose the best as the parents 
    population = population(index(1:parent_number), :); 

    % the best fitness for this generation
    best_fitness(generation) = cost(1); 

    % the best solution for this generation 
    elite(generation, :) = population(1, :); 

    % if it already arrives to the best solution under tolerance, end the
    % loop
    if best_fitness(generation) < minimal_cost 
        last_generation = generation;
        break; 
    end
    
    %% here begins the mutation and crossover 

 
    for child = 1:2:child_number % step=2 for every crossover will have 2 child
        
        % the length of cumulative_probabilities is the length of parent_number
        % coose two parents randomly from (child+parent_number)
        mother = find(cumulative_probabilities > rand, 1); % choose 1 who is better 
        father = find(cumulative_probabilities > rand, 1); 
        
        % ceil 向上取整
        % rand generate a number between [0,1]
        % 交叉位点数
        crossover_point = ceil(rand*number_of_variables); 
        
        % suppose crossover_point=3, number_of_variables=5
        % mask1 = 1     1     1     0     0
        % mask2 = 0     0     0     1     1
        mask1 = [ones(1, crossover_point), zeros(1, number_of_variables - crossover_point)];
        mask2 = not(mask1);
        
        % 获取分开的四段
        mother_1 = mask1 .* population(mother, :);
        mother_2 = mask2 .* population(mother, :); 
        
        father_1 = mask1 .* population(father, :); 
        father_2 = mask2 .* population(father, :); 
        
        % crossover 
        population(parent_number + child, :) = mother_1 + father_2; 
        population(parent_number+child+1, :) = mother_2 + father_1; 
        
    end % end the crossover 
    
    
    %% begin the mutation 
    
    mutation_population = population(2:population_size, :); % elite don't participate the mutation
    
    number_of_elements = (population_size - 1) * number_of_variables; % 全部基因数
    number_of_mutations = ceil(number_of_elements * mutation_rate); % 可变异的基因数量
    % rand(1, number_of_mutations) 生成number_of_mutations个(0-1)之间的随机数组成矩阵（1*number of elements）
    % 确定变异位置
    mutation_points = ceil(number_of_elements * rand(1, number_of_mutations)); 
    
   %被选中的基因被一个随机数代替，完成变异
    mutation_population(mutation_points) = rand(1, number_of_mutations); 
    
    population(2:population_size, :) = mutation_population; % 发生变异后的种群
    
    % mutation finished 
   
end
