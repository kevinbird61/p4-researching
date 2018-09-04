all: basic

basic: basic.p4
	p4c-bm2-ss --std p4-16 \
		--target bmv2 --arch v1model \
		-o basic.json \
		--p4runtime-file basic.p4info \
		--p4runtime-format text basic.p4 

graphs: basic.p4
	p4c-graphs basic.p4 --graphs-dir graphs/
