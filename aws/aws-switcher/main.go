package main

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

const (
	configPath = ".aws/config"
)

var organizations = []string{"COMPANY_A", "COMPANY_B", "PERSONAL"}

type Section struct {
	name     string
	start    int
	end      int
	isActive bool
}

func main() {
	// Get home directory
	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error getting home directory: %v\n", err)
		os.Exit(1)
	}

	configFilePath := filepath.Join(homeDir, configPath)

	// Check if config file exists
	if _, err := os.Stat(configFilePath); os.IsNotExist(err) {
		fmt.Fprintf(os.Stderr, "AWS config file not found at: %s\n", configFilePath)
		os.Exit(1)
	}

	// Read current configuration
	lines, err := readLines(configFilePath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading config file: %v\n", err)
		os.Exit(1)
	}

	// Find sections
	sections := findSections(lines)

	// Display current active organization
	fmt.Println("╔═══════════════════════════════════════════════════════╗")
	fmt.Println("║          AWS Account Organization Switcher           ║")
	fmt.Println("╚═══════════════════════════════════════════════════════╝")
	fmt.Println()

	currentActive := getCurrentActive(sections)
	if currentActive != "" {
		fmt.Printf("📍 Current active organization: \033[1;32m%s\033[0m\n\n", currentActive)
	}

	// Show menu
	fmt.Println("Select the organization you want to activate:")
	fmt.Println()
	for i, org := range organizations {
		indicator := "  "
		if sections[org].isActive {
			indicator = "✓ "
		}
		fmt.Printf("%s%d. %s\n", indicator, i+1, formatOrgName(org))
	}
	fmt.Println()
	fmt.Print("Enter your choice (1-3) or 'q' to quit: ")

	// Read user input
	reader := bufio.NewReader(os.Stdin)
	input, err := reader.ReadString('\n')
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading input: %v\n", err)
		os.Exit(1)
	}

	input = strings.TrimSpace(input)

	// Handle quit
	if input == "q" || input == "Q" {
		fmt.Println("Bye! 👋")
		os.Exit(0)
	}

	// Validate input
	var choice int
	_, err = fmt.Sscanf(input, "%d", &choice)
	if err != nil || choice < 1 || choice > len(organizations) {
		fmt.Fprintf(os.Stderr, "❌ Invalid choice. Please enter a number between 1 and %d.\n", len(organizations))
		os.Exit(1)
	}

	selectedOrg := organizations[choice-1]

	// Check if already active
	if sections[selectedOrg].isActive {
		fmt.Printf("\n✨ %s is already active. No changes needed.\n", formatOrgName(selectedOrg))
		os.Exit(0)
	}

	// Switch organization
	fmt.Printf("\n🔄 Switching to %s...\n", formatOrgName(selectedOrg))

	newLines := switchOrganization(lines, sections, selectedOrg)

	// Create backup
	backupPath := configFilePath + ".backup"
	if err := writeLines(backupPath, lines); err != nil {
		fmt.Fprintf(os.Stderr, "Warning: Could not create backup: %v\n", err)
	}

	// Write new configuration
	if err := writeLines(configFilePath, newLines); err != nil {
		fmt.Fprintf(os.Stderr, "❌ Error writing config file: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("✅ Successfully switched to %s!\n", formatOrgName(selectedOrg))
	fmt.Printf("💾 Backup saved to: %s\n", backupPath)
	fmt.Println()
	fmt.Println("You can now use your AWS CLI with the active organization's profiles.")
}

func readLines(path string) ([]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}

	return lines, scanner.Err()
}

func writeLines(path string, lines []string) error {
	file, err := os.Create(path)
	if err != nil {
		return err
	}
	defer file.Close()

	writer := bufio.NewWriter(file)
	for _, line := range lines {
		fmt.Fprintln(writer, line)
	}

	return writer.Flush()
}

func findSections(lines []string) map[string]Section {
	sections := make(map[string]Section)

	for i, line := range lines {
		trimmed := strings.TrimSpace(line)

		// Check for BEGIN markers
		for _, org := range organizations {
			beginMarker := "## BEGIN " + org
			endMarker := "## END " + org

			if trimmed == beginMarker {
				section := sections[org]
				section.name = org
				section.start = i
				sections[org] = section
			} else if trimmed == endMarker {
				section := sections[org]
				section.end = i
				// Check if section is active (has uncommented lines)
				section.isActive = isSectionActive(lines, section.start, section.end)
				sections[org] = section
			}
		}
	}

	return sections
}

func isSectionActive(lines []string, start, end int) bool {
	for i := start + 1; i < end; i++ {
		line := strings.TrimSpace(lines[i])
		// Skip empty lines and comment-only lines
		if line == "" || strings.HasPrefix(line, "##") {
			continue
		}
		// If we find a line that starts with '[profile' and is not commented, section is active
		if strings.HasPrefix(line, "[profile") {
			return true
		}
	}
	return false
}

func getCurrentActive(sections map[string]Section) string {
	for _, org := range organizations {
		if section, ok := sections[org]; ok && section.isActive {
			return formatOrgName(org)
		}
	}
	return ""
}

func switchOrganization(lines []string, sections map[string]Section, targetOrg string) []string {
	newLines := make([]string, len(lines))
	copy(newLines, lines)

	for _, org := range organizations {
		section := sections[org]
		shouldBeActive := org == targetOrg

		// Process lines in this section
		for i := section.start + 1; i < section.end; i++ {
			line := lines[i]
			trimmed := strings.TrimSpace(line)

			// Skip empty lines and section headers (##)
			if trimmed == "" || strings.HasPrefix(trimmed, "##") {
				continue
			}

			if shouldBeActive {
				// Remove comment if present
				if strings.HasPrefix(trimmed, "#") {
					newLines[i] = strings.TrimPrefix(trimmed, "#")
				}
			} else {
				// Add comment if not present
				if !strings.HasPrefix(trimmed, "#") {
					newLines[i] = "#" + line
				}
			}
		}
	}

	return newLines
}

func formatOrgName(org string) string {
	switch org {
	case "COMPANY_A":
		return "Company A"
	case "COMPANY_B":
		return "Company B"
	case "PERSONAL":
		return "Personal"
	default:
		return org
	}
}
