package main

import (
	"fmt"
	"gospec/database"
	"gospec/rspec"
	"log"
	"os"
	"time"
)

func main() {
	if len(os.Args) == 1 {
		log.Fatalln("Please give filepaths or files to run specs for")
	}
	switch os.Args[1] {
	case "-h", "--help":
		printHelp()
	case "migrate":
		database.PerformOnAll("migrate")
	case "create":
		database.PerformOnAll("create")
	default:
		runSpecs(os.Args[1:])
	}
}

func printHelp() {
	fmt.Println(
		"Gospec usage commands",
		"\ndefault (no command) - runs specs given",
		"\ncreate - creates 10 database copies (via db:create)",
		"\nmigrate - will perform rails migrations on the 10 database copies TEST env",
		"To run specs",
		"\n  to run specs for a single file or directory, paste path to file/directory after gospec",
		"\n    eg: gospec path/to/file_spec.rb",
		"\n  to run specs for a group of files or directories, past all file paths into the commandline after gospec",
		"\n    eg: gospec path/to/file_spec.rb path/to/file_2_spec.rb",
	)
}

func runSpecs(filesOrDirectories []string) {
	files := rspec.GetAllSpecFiles(filesOrDirectories)
	rSpecr := initRspecRunner(files)
	rSpecr.startTime = time.Now()
	rSpecr.run()
	rSpecr.endTime = time.Now()
	rSpecr.logResults()
}
