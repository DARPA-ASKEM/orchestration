# diagram.py
from diagrams import Cluster, Diagram, Edge
from diagrams.aws.storage import S3
from diagrams.custom import Custom
from diagrams.elastic.elasticsearch import Elasticsearch
from diagrams.k8s.network import Ing
from diagrams.onprem.client import Client
from diagrams.onprem.compute import Server
from diagrams.onprem.database import Postgresql
from diagrams.onprem.inmemory import Redis
from diagrams.onprem.logging import Loki
from diagrams.onprem.monitoring import Grafana
from diagrams.onprem.monitoring import Prometheus
from diagrams.onprem.queue import Rabbitmq
from diagrams.programming.flowchart import Database

# Graph Attributes
graph_attr = {
	"bgcolor": "white",
	"center": "true",
	"beautify": "true",
	"layout": "dot",
	"rankdir": "TB",    # Direction of graph, "TB" is top to bottom, "LR" is left to right
	"splines": "ortho", # How edges are drawn. Other options: "ortho", "curved", etc.
	"nodesep": "1",     # Adjust the space between nodes
	"ranksep": "2.0",   # Adjust the space between ranks of nodes
	"margin": "20",     # Margin around the graph
	"pad": "0.5",       # Padding between the graph and the margin
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
	"color": "darkgrey",   # Edge color
	"style": "solid",      # Style of the edge, other options: "solid", "dotted", etc.
	"arrowhead": "normal", # Style of the arrowhead, other options: "normal", "dot", etc.
	"fontname": "Arial",   # Font type
	"fontsize": "10",      # Font size
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

	with Cluster("Managed Data Sources"):
		postgres = Postgresql("PostgreSQL")
		redis = Redis("Redis")
		es = Elasticsearch("Elasticsearch")
		s3 = S3("S3")

	with Cluster("TA4 Kubernetes Cluster"):
		with Cluster("Middle Tier"):
			equation_extraction = Custom("Equation Extraction", "./resources/uncharted.png")
			equation_extraction_taskrunner = Custom("Equation Extraction Taskrunner", "./resources/uncharted.png")
			funman_taskrunner = Custom("Funman Taskrunner", "./resources/uncharted.png")
			gollm = Custom("Gollm", "./resources/uncharted.png")
			gollm_taskrunner = Custom("Gollm Taskrunner", "./resources/uncharted.png")
			hmi_server = Custom("HMI Server", "./resources/uncharted.png")
			keycloak = Custom("Keycloak", "./resources/keycloak.png")
			message_queue = Rabbitmq("Message Queue")
			mira_local = Custom("MIRA", "./resources/uncharted.png")
			mira_taskrunner = Custom("MIRA Taskrunner", "./resources/uncharted.png")
			text_extraction = Custom("Text Extraction", "./resources/uncharted.png")
			text_extraction_taskrunner = Custom("Text Extraction Taskrunner", "./resources/uncharted.png")
			web_servers = [Custom("Web Server", "./resources/uncharted.png"), Custom("Docs Server", "./resources/uncharted.png")]

		with Cluster("Data Sources"):
			spicedb = Database("SpiceDB")
			graphdb = Custom("GraphDB", "./resources/graphdb.png")

		with Cluster("Simulation Services"):
			pyciemss_api = Custom("pyciemss API", "./resources/pnnl.png")
			pyciemss_worker = Custom("pyciemss Worker", "./resources/pnnl.png")
			sciml_service = Custom("SciML Service", "./resources/sciml.png")

		with Cluster("Knowledge Services"):
			beaker = Custom("Beaker", "./resources/jataware.jpeg")
			climate_data_api = Custom("Climate Data API", "./resources/jataware.jpeg")
			climate_data_worker = Custom("Climate Data Worker", "./resources/jataware.jpeg")
			mit_tr = Custom("MIT TR", "./resources/mit.jpeg")
			skema_unified = Custom("Skema Unified", "./resources/ml4ai.png")
			skema_rs = Custom("Skema Rs", "./resources/ml4ai.png")
			skema_tr = Custom("Skema Text Reading", "./resources/ml4ai.png")
			funman = Custom("Funman", "./resources/sift.jpeg")

		with Cluster("Ingress"):
			ingress_app = Ing("application")
			ingress_beaker = Ing("beaker")
			ingress_docs = Ing("documentation")
			ingress_keycloak = Ing("keycloak")

	with Cluster("Jataware External Services"):
		dkg = Server("DKG")

	with Cluster("Public External Services"):
		openai = Server("OpenAI (ChatGPT)")
		github = Server("GitHub API")
		jsdelivr = Server("jsDelivr")
		esgf = Server("ESGF")

	with Cluster("Northwestern External Services"):
		mira = Custom("MIRA", "./resources/northeastern.png")

	with Cluster("UWisc External Services"):
		cosmos = Server("xDD Cosmos")
		xdd = Server("xDD")

	with Cluster("Web Tier"):
		hmi_client = Client("HMI Client")
		docs = Client("Terarium Docs")

	# Connections
	beaker >> Edge() << ingress_beaker
	beaker >> Edge() >> mira
	beaker >> Edge() >> openai
	beaker >> Edge() >> sciml_service
	climate_data_api >> Edge() >> climate_data_worker
	climate_data_worker >> Edge() >> esgf
	climate_data_worker >> Edge() >> openai
	climate_data_worker >> Edge() >> redis
	climate_data_worker >> Edge() >> s3
	equation_extraction_taskrunner >> Edge() >> equation_extraction
	equation_extraction_taskrunner >> Edge() >> message_queue
	funman_taskrunner >> Edge() >> funman
	funman_taskrunner >> Edge() >> message_queue
	gollm_taskrunner >> Edge() >> gollm
	gollm_taskrunner >> Edge() >> message_queue
	grafana >> Edge() >> es
	hmi_client >> Edge() << ingress_beaker
	hmi_client >> Edge() << ingress_keycloak
	hmi_client >> Edge() >> mira
	hmi_server >> Edge() << ingress_app
	hmi_server >> Edge() >> beaker
	hmi_server >> Edge() >> climate_data_api
	hmi_server >> Edge() >> cosmos
	hmi_server >> Edge() >> dkg
	hmi_server >> Edge() >> equation_extraction_taskrunner
	hmi_server >> Edge() >> es
	hmi_server >> Edge() >> funman
	hmi_server >> Edge() >> github
	hmi_server >> Edge() >> gollm_taskrunner
	hmi_server >> Edge() >> graphdb
	hmi_server >> Edge() >> jsdelivr
	hmi_server >> Edge() >> keycloak
	hmi_server >> Edge() >> message_queue
	hmi_server >> Edge() >> mira_taskrunner
	hmi_server >> Edge() >> mit_tr
	hmi_server >> Edge() >> postgres
	hmi_server >> Edge() >> pyciemss_api
	hmi_server >> Edge() >> redis
	hmi_server >> Edge() >> s3
	hmi_server >> Edge() >> sciml_service
	hmi_server >> Edge() >> skema_rs
	hmi_server >> Edge() >> skema_tr
	hmi_server >> Edge() >> skema_unified
	hmi_server >> Edge() >> spicedb
	hmi_server >> Edge() >> text_extraction_taskrunner
	hmi_server >> Edge() >> xdd
	ingress_app >> Edge() << hmi_client
	ingress_docs >> Edge() << docs
	keycloak >> Edge() << ingress_keycloak
	loki >> Edge() >> es
	mira_taskrunner >> Edge() >> message_queue
	mira_taskrunner >> Edge() >> mira_local
	pyciemss_api >> Edge() >> hmi_server
	pyciemss_api >> Edge() >> pyciemss_worker
	pyciemss_api >> Edge() >> redis
	pyciemss_worker >> Edge() >> hmi_server
	pyciemss_worker >> Edge() >> message_queue
	pyciemss_worker >> Edge() >> redis
	sciml_service >> Edge() >> message_queue
	skema_unified >> Edge() >> mit_tr
	skema_unified >> Edge() >> skema_rs
	text_extraction_taskrunner >> Edge() >> message_queue
	text_extraction_taskrunner >> Edge() >> text_extraction
	web_servers >> Edge() << ingress_app
	web_servers >> Edge() << ingress_docs
