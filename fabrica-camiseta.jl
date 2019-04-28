#!/usr/bin/env  julia
using JuMP
using Gurobi

m = Model(with_optimizer(Gurobi.Optimizer))

# Dados
semanas = collect(1:4)
custos = [2, 2, 2.5, 2.5]
demandas = [5000, 10000, 30000, 60000]
custo_por_excesso = 0.2
custo_hora_extra = 0.8
capacidade_maxima = 25000
capacidade_extra_max = 10000

# Variaveis
@variable(m, quantidades[semanas] >= 0, Int)
@variable(m, quantidades_extras[semanas] >= 0, Int)

# Funcao Objetivo
@objective(m, Min, sum(
                        quantidades_extras[i] * (custos[i] + custo_hora_extra)
                        +
                        quantidades[i] * custos[i]
                        +
                        (sum(
                            quantidades[j] + quantidades_extras[j] - demandas[j]
                         for j in collect(1:i)
                        )
                        *
                        custo_por_excesso)
                    for i in semanas
                   )
           )

# Restricoes
@constraints(m,
    begin
        [i in semanas], quantidades[i] <= capacidade_maxima
        [i in semanas], quantidades_extras[i] <= capacidade_extra_max
        [i=3:4], quantidades_extras[i] == 0
        [i in semanas], sum(quantidades[j] + quantidades_extras[j] for j in collect(1:i)) >= sum(demandas[j] for j in collect(1:i)) 
    end
)
                    
# Printa modelo
println(m)


start_time = time()
optimize!(m)
end_time = time()
println("Tempo: $(end_time - start_time) s")
println("Resultado função: ", JuMP.objective_value(m))

for i in semanas
    if (JuMP.value(quantidades[i]) > 0)
        println("quantidades[", i, "]: ", JuMP.value(quantidades[i]))
    elseif (JuMP.value(quantidades[i]) == 0)
        println("quantidades[", i, "]: ", 0.0)
    end
    if (JuMP.value(quantidades_extras[i]) > 0)
        println("quantidades_extras[", i, "]: ", JuMP.value(quantidades_extras[i]))
    elseif (JuMP.value(quantidades_extras[i]) == 0)
        println("quantidades_extras[", i, "]: ", 0.0)
    end
end
        
