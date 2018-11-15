all: tutorial_switch

tutorial_switch: psa_tutorial_switch.p4
	p4c-bm2-psa --std p4-16 \
		--target bmv2 --arch psa \
		-o psa_tutorial_switch.json \
		--p4runtime-file psa_tutorial_switch.p4info \
		--p4runtime-format text psa_tutorial_switch.p4