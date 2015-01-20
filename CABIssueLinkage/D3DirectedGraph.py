from IPython.html import widgets
from IPython.utils.traitlets import Unicode, CInt, CFloat,List
from IPython.display import display, Javascript
from networkx.readwrite import json_graph

def publish_js():
    with open('./D3DirectedGraph.js', 'r') as f:
        display(Javascript(data=f.read()))

class D3DirectedGraph(widgets.DOMWidget):
    _view_name = Unicode('D3DirectedGraph', sync=True)
    width = CInt(960, sync=True)
    height = CInt(500, sync=True)
    charge = CFloat(500, sync=True)
    distance = CInt(75, sync=True)
    strength = CInt(0.3, sync=True)
    nodes = List(sync=True)
    links = List(sync=True)
    max_node_size = CInt(40, sync=True)
    min_node_size = CInt(8, sync=True)
    node_color = Unicode("DarkGray", sync=True)
    node_font = Unicode("12px sans-serif", sync=True)
    node_highlight_color = Unicode("CornflowerBlue", sync=True)
    node_highlight_scale = CFloat(1.5, sync=True)
    max_link_width = CFloat(5.0, sync=True)
    min_link_width = CFloat(0.5, sync=True)
    link_color = Unicode("Black", sync=True)
    tooltip_color = Unicode("LightGreen", sync=True)
    tooltip_font = Unicode("15px sans-serif", sync=True)

    def __init__(self, graph, *pargs, **kwargs):
        widgets.DOMWidget.__init__(self, *pargs, **kwargs)
        graph_json = json_graph.node_link_data(graph)
        self.nodes = graph_json['nodes']
        self.links = graph_json['links']

