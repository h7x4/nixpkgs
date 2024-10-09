### Overview of things done

- Set options/configuration/services directly in module, don't pass through utils functions
- Remove defaults telling you to set a value / throw. The module system will handle reporting unset required options.
- Reduplicate a few of the most forcefully duplicated config blocks.
- Remove a bunch of `internal = true` expressions, ensuring users can find the options they are looking for. If something is not meant to be modified, `readonly` might be a better option.
- Convert utils into a module template, with the componentName being the single variable. Rename to `common.nix`
- Commonize postgresql config, and don't assume that the postgres config will be local
- Inject secrets for postgres and initialAccounts into config file
- Basic systemd hardening. I've done my best not to make any controversial choices, and only gone for the most low hanging fruit. There is room for improvement here
-

### Questions

- Is it correct that nexus and bank is supposed to have r/w access to each other's databases? Should they
-


