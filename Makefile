.PHONY: test

# Run the Plenary/Busted test suite headlessly. Test dependencies (plenary,
# telescope) are resolved by tests/minimal_init.lua.
test:
	nvim --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua', sequential = true}"
