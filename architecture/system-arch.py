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
			hmi_server = Pod("HMI Server")
			web_servers = [Pod("Web Server"), Pod("Docs Server")]
			gateway = Custom("Gateway", "./resources/apache.png")
			keycloak = Custom("Keycloak", "./resources/keycloak.png")
			message_queue = Rabbitmq("Message Queue")
			llm = Pod("Jupyter LLM")
			hmi_extraction_service = Pod("HMI Extraction Service")

		with Cluster("Data Tier"):
			tds = Pod("Data Service (TDS)")
			graphdb = Custom("GraphDB", "./resources/graphdb.png")

		with Cluster("Model Services"):
			model_service = Pod("Model Service")

		with Cluster("Simulation Services"):
			pyciemss_api = Pod("pyciemss API")
			pyciemss_worker = Pod("pyciemss Worker")
			simulation_service = Pod("Simulation Service")

		with Cluster("Knowledge Services"):
			knowledge_middleware_api = Pod("Knowledge Middleware API")
			knowledge_middleware_worker = Pod("Knowledge Middleware Worker")
			skema_unified = Pod("Skema Unified")
			skema_rs = Pod("Skema RS")
			skema_tr = Pod("Skema TR")
			mit_tr = Pod("MIT TR")
			skema_memgraph = Pod("Skema Memgraph")

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
		mit_tr_external = Server("MIT TR")

	with Cluster("Web Tier"):
		with Cluster("Users"):
			hmi_client = Client("HMI Client")
			docs = Client("Terarium Docs")
		with Cluster("Admins"):
			admin_ui = Client("Admin UI")

	# Connections
	knowledge_middleware_api >> Edge() >> redis
	knowledge_middleware_worker >> Edge() >> cosmos
	knowledge_middleware_worker >> Edge() >> mit_tr_external
	knowledge_middleware_worker >> Edge() >> redis
	knowledge_middleware_worker >> Edge() >> skema_rs
	knowledge_middleware_worker >> Edge() >> skema_unified_external
	knowledge_middleware_worker << Edge() >> tds
	gateway >> Edge() << ingress_app
	gateway >> Edge() << ingress_docs
	gateway >> Edge() << keycloak
	grafana >> Edge() >> es
	hmi_server << Edge() >> pyciemss_api
	hmi_server >> Edge() << gateway
	hmi_server >> Edge() << keycloak
	hmi_server >> Edge() << llm
	hmi_server >> Edge() << tds
	hmi_server >> Edge() >> github
	hmi_server >> Edge() >> hmi_extraction_service
	hmi_server >> Edge() >> jsdelivr
	hmi_server >> Edge() >> message_queue
	hmi_server >> Edge() >> model_service
	hmi_server >> Edge() >> pyciemss_api
	hmi_server >> Edge() >> simulation_service
	hmi_server >> Edge() >> xdd
	hmi_extraction_service << Edge() >> knowledge_middleware_api
	ingress_app >> Edge() << hmi_client
	ingress_docs >> Edge() << docs
	ingress_keycloak >> Edge() << admin_ui
	keycloak >> Edge() << ingress_keycloak
	llm >> Edge() >> openai
	llm >> Edge() >> simulation_service
	loki	>> Edge() >> es
	pyciemss_api >> Edge() >> redis
	pyciemss_api >> Edge() >> tds
	pyciemss_worker >> Edge() >> redis
	pyciemss_worker >> Edge() >> tds
	skema_rs >> Edge() >> skema_memgraph
	skema_unified >> Edge() >> mit_tr
	skema_unified >> Edge() >> skema_rs
	skema_unified >> Edge() >> skema_tr
	tds >> Edge() >> dkg
	tds >> Edge() >> es
	tds >> Edge() >> graphdb
	tds >> Edge() >> message_queue
	tds >> Edge() >> postgres
	tds >> Edge() >> redis
	tds >> Edge() >> s3
	web_servers << Edge() << gateway
