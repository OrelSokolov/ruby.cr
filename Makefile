.PHONY: oracle current compare review spec all

oracle:      ## снять слепки с настоящего Ruby (обе версии)
	bin/record-ruby v3
	bin/record-ruby v4

current:     ## снять слепки с Ruby::V3/V4 (Crystal)
	bin/record-crystal v3
	bin/record-crystal v4

compare:     ## переснять всё и сверить деревья слепков (twinshot)
	bin/record-ruby v3 && bin/record-ruby v4
	bin/record-crystal v3 && bin/record-crystal v4
	twinshot compare all

review:      ## regenerate + compare одной командой
	twinshot review all

spec:        ## юнит-тесты Crystal
	crystal spec

all: compare spec
