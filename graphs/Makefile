all: graphs

graphs: l3_forward.p4
	p4c-graphs --std p4-16 l3_forward.p4
	dot -Tpng Basic_parser.dot > parser.png
	dot -Tpng Basic_ingress.dot > ingress.png
	dot -Tpng Basic_deparser.dot > deparser.png
