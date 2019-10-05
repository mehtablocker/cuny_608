### This API takes in any of the five boroughs and returns all unique tree species in that borough

from flask import Flask, jsonify
import pandas as pd

app = Flask(__name__)


@app.route('/trees/<string:boro>')
def return_complex(boro):
    boro = boro.replace(' ', '%20')
    
    try:
        url = "https://data.cityofnewyork.us/resource/nwxe-4ae8.json?$limit=1000000&$where=boroname='" + boro + "'"
        trees = pd.read_json(url)
        species_list = pd.Series(trees['spc_common'].unique()).dropna().sort_values().tolist()
        species_dict = {}
        for i in species_list:
            species_dict[i] = boro
        return jsonify(species_dict)
    
    except:
        return "Check syntax! Choices are only Manhattan, Bronx, Brooklyn, Queens, or Staten Island."


if __name__ == '__main__':
    app.run(debug=True)
