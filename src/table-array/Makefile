all: fivetuple

fivetuple: five_tuple_table_register.p4
	p4c-bm2-ss --std p4-16 \
		--target bmv2 --arch v1model \
		-o five_tuple_table_register.json \
		--p4runtime-file five_tuple_table_register.p4info \
		--p4runtime-format text five_tuple_table_register.p4

controller: p4_controller.py
	sudo python p4_controller.py
