from __future__ import division, print_function
from collections import defaultdict, OrderedDict, Counter
from dateutil.parser import parse
import operator
import json
import requests
import numpy as np
from scipy.stats import beta
import networkx
from networkx.readwrite import json_graph
from D3DirectedGraph import D3DirectedGraph
from IPython.html import widgets
from IPython.display import display

def load_data(region, size=10000):
    query_dict = {"fields": ["client_profile_id","timestamp","issue_codes.aic_3_name"],
                  "query": {"bool":{"must": [{"match_phrase": {"member_govregion_name": region}}],
                                    "must_not": [{"match_phrase": {"issue_codes.aic_3_name": "Other"}}]}},
                  "filter": {"exists": {"field": ["client_profile_id","timestamp","issue_codes.aic_3_name"]}},
                  "sort": {"timestamp": {"order": "desc"}},
                  "size": size}
    query_json = json.dumps(query_dict)
    response = requests.get('http://localhost:9200/visits/_search',data=query_json)
    response_objs = (record['fields'] for record in response.json()['hits']['hits'])
    
    # Create a dict. The keys are the ClientProfiles, the values are an Dict with date key and list of p3s as value
    all_visits = defaultdict(lambda : defaultdict(list))
    for record in response_objs:
        visit_date = parse(record['timestamp'][0])
        client_profile = record['client_profile_id'][0]
        p3 = record['issue_codes.aic_3_name'][0]
##        p3 = p3[p3.find(" ")+1:]  # Strip off the first two letters of P3 names
        p3 = p3.replace("@",",")
        client_visits = all_visits[client_profile]
        client_visits[visit_date].append(p3)
    # turn the dict of dicts of lists to dict of OrderedDicts of frozensets ordered by visit date for faster handling
    all_visits = {client:OrderedDict(map(lambda (visit_date, p3s): (visit_date,frozenset(p3s)), 
                                         sorted(visits.items(), key=lambda t: t[0]))) for client,visits in all_visits.iteritems()}
    return all_visits


def get_top_issues(all_visits,n):
    issues = Counter(issue for client_visits in all_visits.itervalues() 
                     for issues in client_visits.itervalues() for issue in issues)
    return issues.most_common(n)


def get_and_cleanse_data(region, max_number_of_visits=100, max_number_of_issues=20):
    all_visits = load_data(region,max_number_of_visits)
    top_issues = get_top_issues(all_visits,max_number_of_issues)
    return top_issues, all_visits


def filter_visits_by_issues(visits, issue_set):
    # remove the issues that not are in the issue_set
    visits = {client_id:{client_visit_date:client_visit_issues.intersection(issue_set) 
                         for client_visit_date,client_visit_issues in client_record.iteritems()} 
              for client_id,client_record in visits.iteritems() }
    # remove visits that are empty
    visits = {client_id:{visit_date:visit_issues 
                         for visit_date,visit_issues in client_record.iteritems() if len(visit_issues)>0}
              for client_id,client_record in visits.iteritems()}
    return visits


def get_issue_lift(all_visits, top_issues, half_life=90, min_lift=1):
    """
    get_issue_lift uses the bureau visit data and calculate the lift between issues
    i.e. if a client ask for help for issue A, is he more likely to ask for help for issue B in the future?
    mathematically it is defined as P(B|A)/P(B). If the lift is > 1 than A is a good indicator that of
    future need of B. The half_life allows for aging i.e. the importance of issue A as a predictor of B
    halves every x days.
    Return a dict  {(issue_A, issue_B):lift}
    """    
    number_of_clients = len(all_visits)
    
    # Remove "Other" from top_issues
    for i in xrange(len(top_issues)):
        if top_issues[i][0]=="Other":
            del top_issues[i]
            break
    
    # Save time and only calculate for the top issues
    top_issue_set = frozenset(map(operator.itemgetter(0), top_issues))
    all_visits = filter_visits_by_issues(all_visits, top_issue_set)
    
    # Count the number of clients affected by each of the top issue
    issue_count = {issue:sum(any(issue in visit_issues for visit_issues in client_visits.itervalues())
                       for client_visits in all_visits.itervalues()) for issue in top_issue_set}
    
    # Iterate through the clients and find all A->B pairs and their ages
    # for each A->B pair only take the one that is closest together
    decay = 0.5**(1.0/half_life)
    lift_dict = defaultdict(float)
    for client_id, client_visits in all_visits.iteritems():
        number_of_visits = len(client_visits)
        visit_days = sorted(client_visits.keys())
        client_pairs = {}
        for i in xrange(number_of_visits):
            current_date = visit_days[i]
            current_issues = client_visits[current_date]
            for issue_A in current_issues:
                for future_date in visit_days[i+1:]:
                    gap = (future_date-current_date).days
                    future_issues = client_visits[future_date]
                    for issue_B in future_issues:
                        if issue_A!=issue_B:
                            client_pairs[(issue_A,issue_B)] = min(gap, client_pairs.get((issue_A,issue_B),1e100))
        # Turn the gaps into weights and add to the lift dict
        for pair,gap in client_pairs.iteritems():
            lift_dict[pair] += decay**gap
            
    # turn the appearance count into lifts
    for (issue_A,issue_B),count in lift_dict.iteritems():
        p_issues_A_B = beta.rvs(1+count,1+issue_count[issue_B]-count,size=10000)
        p_issue_A = beta.rvs(1+issue_count[issue_A], 1+number_of_clients-issue_count[issue_A],size=10000)
        lift_dict[(issue_A, issue_B)] = np.median((p_issues_A_B-p_issue_A)/p_issue_A)+1
        
    # Filter out the pairs below the threshold
    lift_dict = {pair:lift for pair,lift in lift_dict.iteritems() if lift>min_lift}
    return lift_dict


def build_graph(issues, lifts):
    graph = networkx.DiGraph()
    for issue,weight in issues:
        graph.add_node(issue,count=weight)
    graph.add_weighted_edges_from((issueA,issueB,lift) for (issueA,issueB),lift in lifts.iteritems())
    return graph


existing_graphs = []


def CAB_issue_linkage(region, max_number_of_records, max_number_of_nodes, half_life=90, min_lift=1.0):
    height=500
    width=960
    for old_graph in existing_graphs:
        old_graph.close()
    del existing_graphs[:]
    top_issues, all_visits = get_and_cleanse_data(region, max_number_of_records, max_number_of_nodes)
    lifts = get_issue_lift(all_visits, top_issues, half_life, min_lift)
    if lifts:
        graph = build_graph(top_issues, lifts)
        d3graph = D3DirectedGraph(graph)
        d3graph.height = height
        d3graph.width = width
        d3graph.node_color = "DarkOrange"
        d3graph.tooltip_color = "LightGray"
        d3graph.node_highlight_color = "Gold"
        d3graph.max_node_size = 50
        d3graph.min_node_size = 5
        d3graph.max_link_width = 7.0
        d3graph.min_link_width = 0.5
        existing_graphs.append(d3graph)
        display(d3graph)
    else:
        warning_text = widgets.HTMLWidget(value='<DIV>Not enough data</DIV')
        warning_text.set_css({'height':'%dpx'%height, 'width':'%dpx'%width, 'line-height':'%dpx'%height, 'text-align':'center', 'vertical-align':'middle'})
        existing_graphs.append(warning_text)
        display(warning_text)
