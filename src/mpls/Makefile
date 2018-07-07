all: run

# set all output filename to `target`
run: mpls.p4
	p4c-bm2-ss --std p4-16 \
		--target bmv2 --arch v1model \
		-o target.json \
		--p4runtime-file target.p4info \
		--p4runtime-format text mpls.p4

controller: p4_controller.py
	sudo python p4_controller.py \
		--p4info target.p4info \
		--bmv2-json target.json
