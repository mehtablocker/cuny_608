import dash
import dash_core_components as dcc
import dash_html_components as html
from dash.dependencies import Input, Output, State
import dash_table
import dash_table.FormatTemplate as FormatTemplate
import pandas as pd
import numpy as np
import pandas_datareader.data as pdr
import datetime as dt

external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css']


app = dash.Dash(__name__, external_stylesheets=external_stylesheets)

app.layout = html.Div(children=[
        html.H1('Get Tree Health Proportions:'), 
        dcc.Dropdown(
                id='boro_input', 
                options=[
                        {'label': 'Bronx', 'value': 'Bronx'},
                        {'label': 'Brooklyn', 'value': 'Brooklyn'},
                        {'label': 'Manhattan', 'value': 'Manhattan'},
                        {'label': 'Queens', 'value': 'Queens'},
                        {'label': 'Staten Island', 'value': 'Staten%20Island'}
                        ],
                value='Manhattan'
                ),
        dcc.Input(id='spc_common_input', value='magnolia', type='text'),
        html.Button('Submit', id='button', n_clicks=0),
        html.Div(id='container-button-basic',
                 children='Pick a Borough and enter a Tree Species')
        ])

@app.callback(
        Output(component_id = 'container-button-basic', component_property = 'children'), 
        [Input(component_id = 'button', component_property = 'n_clicks')],   #this rigs it so the output only updates when n_clicks changes
        state=[State(component_id='boro_input', component_property='value'),
               State(component_id='spc_common_input', component_property='value')]
        )
def update_output(n_clicks, boro, spc_common):
    if n_clicks>0:
        url = "https://data.cityofnewyork.us/resource/nwxe-4ae8.json?$limit=1000000&$where=boroname='" + boro + "'"
        trees = pd.read_json(url)
        species_list = pd.Series(trees['spc_common'].unique()).dropna().sort_values().tolist()
        
        try:        
            df = trees.query('spc_common == "' + spc_common + '"')
            df_cont = pd.crosstab(df.health, df.steward, margins=True, normalize=True).round(3)
            df_cont.columns = df_cont.columns + ' Stewards'
            df_cont = df_cont.rename(columns={'All Stewards': 'All'})
            df_cont.index.name = 'Health'
            df_cont.reset_index(inplace = True)
            first_col_format = {"name": df_cont.columns[0], "id": df_cont.columns[0], "type": "text"}
            col_format = [{"name": i, "id": i, "type": "numeric", "format": FormatTemplate.percentage(1)} for i in df_cont.columns[1:]]
            col_format.insert(0, first_col_format)
    
            return (html.Iframe(srcDoc=boro.replace('%20', ' ') + " species choices: " + str(species_list)[1:-1]),
                    
                    dash_table.DataTable(
                            id='table',
                            columns=col_format,
                            data=df_cont.to_dict('records'),
                            )
                    )
        
        except:
            return ("Check syntax of tree species!!!", 
                    
                    html.Iframe(srcDoc=boro.replace('%20', ' ') + " species choices: " + str(species_list)[1:-1])
                    )


if __name__== '__main__':
    app.run_server(debug=True)

        