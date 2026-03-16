#%% O APLICATIVO FINAL (DINÂMICO E EM CASCATA)
import pandas as pd
import joblib

#acorda o modelo guardado e as colunas
modelo = joblib.load('modelo_whey.pkl')
colunas_treino = joblib.load('colunas_treino.pkl')

#carrega os wheys
tabela_wheys = pd.read_excel('qtd_doseWhey.xlsx')

print("\n" + "="*50)
print("      SISTEMA DE PREVISÃO DE ACNE - WHEY      ")
print("="*50)

#pega os dados do user
tipo_pele = input("Qual o seu tipo de pele? (oleosa/mista/seca/normal): ").strip().lower()
tendencia = input("Tem tendência natural a ter acne? (sim/nao): ").strip().lower()

print("\n" + "-"*50)
print("              ESCOLHA O PRODUTO               ")
print("-"*50)

#pergunta o sabor p user
sabores_disponiveis = tabela_wheys['sabor'].unique()
print(f"Sabores disponíveis: {', '.join(sabores_disponiveis)}")
sabor_escolhido = input("Digite o sabor desejado: ").strip().lower()

#filtra p ver os tipos de whey do sabor q o user escolheu
wheys_do_sabor = tabela_wheys[tabela_wheys['sabor'] == sabor_escolhido]

if wheys_do_sabor.empty:
    print("\nOPÇÃO INVÁLIDA: Sabor não encontrado no banco de dados.")
    print("Por favor, rode o programa novamente.")
else:
    #puxa os tipos únicos da tabela nova filtrada
    tipos_disponiveis = wheys_do_sabor['tipo_proteina'].unique()
    
    print(f"\nPara o sabor '{sabor_escolhido.title()}', temos os seguintes tipos:")
    print(f"{', '.join(tipos_disponiveis)}")
    tipo_escolhido = input("Digite o tipo de proteína desejado: ").strip().lower()

    #filtra mais uma vez para pegar a linha exata do produto final
    whey_selecionado = wheys_do_sabor[wheys_do_sabor['tipo_proteina'] == tipo_escolhido]

    if whey_selecionado.empty:
        print("\nOPÇÃO INVÁLIDA: Esse tipo de proteína não está disponível para este sabor.")
    else:
        print("\nProduto encontrado! Analisando os ingredientes...")
        
        #pega os dados exatos daquela linha da planilha
        whey_real = whey_selecionado.iloc[0]

        #monta o produto para o modelo (1 linha cheia de ZEROS)
        whey_usuario = pd.DataFrame(0, index=[0], columns=colunas_treino)

        #liga os botões do "One-Hot Encoding" de forma dinâmica
        coluna_sabor = f"sabor_{sabor_escolhido}"
        coluna_tipo = f"tipo_proteina_{tipo_escolhido}"

        if coluna_sabor in colunas_treino:
            whey_usuario[coluna_sabor] = 1
        if coluna_tipo in colunas_treino:
            whey_usuario[coluna_tipo] = 1

        #puxa os nutrientes exatos da tabela para a previsão
        whey_usuario['lactose'] = whey_real['lactose']
        whey_usuario['acucar_total_100g'] = whey_real['acucar_total_100g']
        whey_usuario['gordura_total_100g'] = whey_real['gordura_total_100g']
        whey_usuario['bcaa_100g'] = whey_real['bcaa_100g']

        #previsão e regra de negocio
        taxa_base = modelo.predict(whey_usuario)[0]
        multiplicador = 1.0

        if tipo_pele == 'oleosa':
            multiplicador += 0.40  
        elif tipo_pele == 'mista':
            multiplicador += 0.20  
        elif tipo_pele == 'seca':
            multiplicador -= 0.10  

        if tendencia == 'sim':
            multiplicador += 0.50  

        probabilidade_final = (taxa_base * multiplicador) * 100
        taxa_base_percentagem = taxa_base * 100

        #resultado
        print("\n" + "="*50)
        print("                   RESULTADO                  ")
        print("="*50)
        print(f"Produto: Whey {tipo_escolhido.title()} de {sabor_escolhido.title()}")
        print(f"1. Risco isolado da fórmula causar acne: {taxa_base_percentagem:.1f}%")
        print(f"2. Probabilidade final para a SUA pele: {probabilidade_final:.1f}%")
        print("="*50)

#%%