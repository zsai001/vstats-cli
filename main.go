package main

import (
	"fmt"
	"os"

	"github.com/zsai001/vstats-cli/internal/commands"
)

var Version = "dev"

func main() {
	commands.SetVersion(Version)

	if err := commands.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
