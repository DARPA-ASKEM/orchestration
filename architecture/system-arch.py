# diagram.py
from diagrams import Cluster, Diagram, Edge
from diagrams.aws.storage import S3
from diagrams.custom import Custom
from diagrams.elastic.elasticsearch import Elasticsearch
from diagrams.k8s.compute import Pod
from diagrams.k8s.network import Ing
from diagrams.onprem.auth import Oauth2Proxy
from diagrams.onprem.client import Client
from diagrams.onprem.compute import Server
from diagrams.onprem.database import Postgresql
from diagrams.onprem.inmemory import Redis
from diagrams.onprem.logging import Loki
from diagrams.onprem.monitoring import Grafana
from diagrams.onprem.monitoring import Prometheus
from diagrams.onprem.network import Apache
from diagrams.onprem.queue import Rabbitmq
from diagrams.programming.flowchart import Database

# Graph Attributes
graph_attr = {
	"bgcolor": "white",
	"center": "true",
	"beautify": "true",
	"layout": "dot",
    "rankdir": "TB",          # Direction of graph, "TB" is top to bottom, "LR" is left to right
    "splines": "spline",    # How edges are drawn. Other options: "ortho", "curved", etc.
    "nodesep": "1",         # Adjust the space between nodes
    "ranksep": "2.0",         # Adjust the space between ranks of nodes
    "margin": "0.5",          # Margin around the graph
    "pad": "0.5",             # Padding between the graph and the margin
    "dpi": "120"
}

node_attr = {
    "style": "filled",        # Filled color for node
    "shape": "box",           # Shape of the node
    "fillcolor": "lightblue", # Node fill color
    "fontname": "Arial",      # Font type
    "fontsize": "10",         # Font size
    "fontcolor": "black"      # Font color
}

edge_attr = {
    "color": "darkgrey",        # Edge color
    "style": "solid",       # Style of the edge, other options: "solid", "dotted", etc.
    "arrowhead": "normal",      # Style of the arrowhead, other options: "normal", "dot", etc.
    "fontname": "Arial",     # Font type
    "fontsize": "10",        # Font size
}

# Nodes
with Diagram("Terarium System Architecture", show=True,
	graph_attr=graph_attr,
	node_attr=node_attr,
	edge_attr=edge_attr):

	with Cluster("Logging and Monitoring"):
		grafana = Grafana("Grafana")
		loki = Loki("Loki")
		prometheus = Prometheus("Prometheus")

	with Cluster("Data Sources"):
		postgres = Postgresql("PostgreSQL")
		redis = Redis("Redis")
		es = Elasticsearch("Elasticsearch")
		s3 = S3("S3")

	with Cluster("TA4 Kubernetes Cluster"):
		with Cluster("Middle Tier"):
			hmi_server = Custom("HMI Server", "./resources/uncharted.png")
			web_servers = [Custom("Web Server", "./resources/uncharted.png"), Custom("Docs Server", "./resources/uncharted.png")]
			keycloak = Custom("Keycloak", "./resources/keycloak.png")
			message_queue = Rabbitmq("Message Queue")
			llm = Custom("Jupyter LLM", "./resources/jataware.jpeg")
			hmi_extraction_service = Custom("HMI Extraction Service", "./resources/uncharted.png")

		with Cluster("Data Tier"):
			tds = Custom("Data Service (TDS)", "./resources/jataware.jpeg")
			graphdb = Custom("GraphDB", "./resources/graphdb.png")

		with Cluster("Model Services"):
			model_service = Custom("Model Service", "./resources/uncharted.png")

		with Cluster("Simulation Services"):
			pyciemss_api = Custom("pyciemss API", "./resources/pnnl.png")
			pyciemss_worker = Custom("pyciemss Worker", "./resources/pnnl.png")
			sciml_service = Custom("SciML Service", "./resources/sciml.png")

		with Cluster("Knowledge Services"):
			knowledge_middleware_api = Custom("Knowledge Middleware API", "./resources/jataware.jpeg")
			knowledge_middleware_worker = Custom("Knowledge Middleware Worker", "./resources/jataware.jpeg")
			mit_proxy = Custom("MIT Proxy", "./resources/uncharted.png")
			mit_tr = Custom("MIT TR", "./resources/mit.jpeg")
			skema_unified = Custom("Skema Unified", "./resources/ml4ai.png")
			skema_py = Custom("Skema Py", "./resources/ml4ai.png")
			skema_rs = Custom("Skema Rs", "./resources/ml4ai.png")
			skema_tr = Custom("Skema TR", "./resources/ml4ai.png")
			skema_eq2mml = Custom("Skema EQ2MML", "./resources/ml4ai.png")
			skema_mathjax = Custom("Skema MathJax", "./resources/ml4ai.png")
			skema_memgraph = Custom("Skema Memgraph", "./resources/ml4ai.png")

		with Cluster("Ingress"):
			ingress_app = Ing("application")
			ingress_docs = Ing("documentation")
			ingress_keycloak = Ing("keycloak")

	with Cluster("Jataware External Services"):
		dkg = Server("DKG")

	with Cluster("Public Eternal Services"):
		openai = Server("OpenAI (ChatGPT)")
		github = Server("GitHub API")
		jsdelivr = Server("jsDelivr")

	with Cluster("UWisc External Services"):
		cosmos = Server("xDD Cosmos")
		xdd = Server("xDD")

	with Cluster("TA1 External Services"):
		skema_unified_external = Server("TA1 Unified")

	with Cluster("Web Tier"):
		hmi_client = Client("HMI Client")
		docs = Client("Terarium Docs")

	# Connections
	grafana >> Edge() >> es
	hmi_extraction_service >> Edge() >> knowledge_middleware_api
	hmi_server >> Edge() >> pyciemss_api
	hmi_server >> Edge() << ingress_app
	hmi_server >> Edge() >> keycloak
	hmi_server >> Edge() >> llm
	hmi_server >> Edge() >> tds
	hmi_server >> Edge() >> github
	hmi_server >> Edge() >> hmi_extraction_service
	hmi_server >> Edge() >> jsdelivr
	hmi_server >> Edge() >> knowledge_middleware_api
	hmi_server >> Edge() >> message_queue
	hmi_server >> Edge() >> model_service
	hmi_server >> Edge() >> pyciemss_api
	hmi_server >> Edge() >> sciml_service
	hmi_server >> Edge() >> xdd
	ingress_app >> Edge() << hmi_client
	ingress_docs >> Edge() << docs
	keycloak >> Edge() << ingress_keycloak
	knowledge_middleware_api >> Edge() >> knowledge_middleware_worker
	knowledge_middleware_api >> Edge() >> redis
	knowledge_middleware_worker << Edge() >> mit_proxy
	knowledge_middleware_worker << Edge() >> tds
	knowledge_middleware_worker >> Edge() >> cosmos
	knowledge_middleware_worker >> Edge() >> redis
	knowledge_middleware_worker >> Edge() >> skema_unified
	knowledge_middleware_worker >> Edge() >> skema_unified_external
	llm >> Edge() >> openai
	llm >> Edge() >> sciml_service
	loki >> Edge() >> es
	mit_proxy >> Edge() >> mit_tr
	pyciemss_api >> Edge() >> pyciemss_worker
	pyciemss_api >> Edge() >> redis
	pyciemss_api >> Edge() >> tds
	pyciemss_worker >> Edge() >> redis
	pyciemss_worker >> Edge() >> tds
	skema_rs >> Edge() >> skema_memgraph
	skema_unified >> Edge() >> skema_py
	skema_unified >> Edge() >> skema_rs
	skema_unified >> Edge() >> skema_tr
	tds >> Edge() >> dkg
	tds >> Edge() >> es
	tds >> Edge() >> graphdb
	tds >> Edge() >> message_queue
	tds >> Edge() >> postgres
	tds >> Edge() >> redis
	tds >> Edge() >> s3
	web_servers >> Edge() << ingress_app
	web_servers >> Edge() << ingress_docs
