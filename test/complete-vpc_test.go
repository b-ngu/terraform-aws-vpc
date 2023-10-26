// // This Terratest file is here to serve as an example of a test structure
// // You may use bits and pieces of this to suit your needs

package test

// This Terratest file is here to serve as an example of a test structure
// You may use bits and pieces of this to suit your needs

import (
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

var (
	//Test Driven tests Inputs https://github.com/golang/go/wiki/TableDrivenTests
	testCases = []struct {
		name   string
		region string
		values map[string]string
	}{
		{
			"complete-vpc",
			"us-west-2",
			map[string]string{
				"rootFolder":        "../",
				"exampleFolderPath": "examples/complete-vpc"},
		},
	}
	/*Update the expected Output variables and values*/
	outputParameters = [...]Outputs{
		{"vpc_cidr_block", "10.0.0.0/16", "equal"},
		{"vpc_enable_dns_hostnames", "true", "equal"},
		{"private_subnets_cidr_blocks", "[10.0.10.0/24 10.0.11.0/24]", "equal"},
		{"public_subnets_cidr_blocks", "[10.0.0.0/24 10.0.1.0/24]", "equal"},
		{"vpc_flow_log_cloudwatch_iam_role_arn", "", "empty"},
		{"vpc_flow_log_destination_arn", "arn:aws:s3:::global-flow-logs-us-west-2", "equal"},
		{"vpc_flow_log_destination_type", "s3", "equal"},
		{"vpc_flow_log_id", "fl-09a6aa603a2f0312d", "notempty"},
	}
)

type Outputs struct {
	OutputVariable      string
	ExpectedOutputValue string
	AssertType          string
}

func getTerraformOptions(t *testing.T, inputTfOptions *terraform.Options) *terraform.Options {
	return terraform.WithDefaultRetryableErrors(t, inputTfOptions)
}

func TestCompleteVpc(t *testing.T) {
	t.Parallel()

	for _, testCase := range testCases {
		testCase := testCase
		t.Run(testCase.name, func(subT *testing.T) {
			subT.Parallel()
			tempExampleFolder := test_structure.CopyTerraformFolderToTemp(t, testCase.values["rootFolder"], testCase.values["exampleFolderPath"])

			inputTfOptions := &terraform.Options{
				NoColor:      true,
				TerraformDir: tempExampleFolder,
				VarFiles:     []string{"fixtures.us-west-2.tfvars"},

				//Vars is left here as an example of how to pass vars without using a tfvars file, similar to how you would by using the -var terraform CLI argument
				// Vars: map[string]interface{}{
				// 	"cluster_name:" "terratest-eks"
				// 	"contact": "name@example.com"
				// 	"environment": "sbx"
				// 	"team": "team"
				// 	"purpose": "terratest"
				// },
			}

			terratestOptions := getTerraformOptions(t, inputTfOptions)

			//* At the end of the test, run `terraform destroy` to clean up any resources that were created */
			defer test_structure.RunTestStage(t, "destroy", func() {
				terraformOptions := getTerraformOptions(t, inputTfOptions)
				terraform.Destroy(t, terraformOptions)
			})

			// Run Init and Apply
			test_structure.RunTestStage(t, "apply", func() {
				test_structure.SaveTerraformOptions(t, tempExampleFolder, terratestOptions)
				terraform.InitAndApplyE(t, terratestOptions)
			},
			)

			t.Run("TF_PLAN_VALIDATION", func(t *testing.T) {
				// Run Plan diff
				test_structure.RunTestStage(t, "plan", func() {
					terraformOptions := test_structure.LoadTerraformOptions(t, tempExampleFolder)
					planResult := terraform.Plan(t, terraformOptions)

					// Make sure the plan shows zero changes
					assert.Contains(t, planResult, "No changes.")
				})
			})

			t.Run("TF_OUTPUTS_VALIDATION", func(t *testing.T) {
				/*Outputs Validation*/
				test_structure.RunTestStage(t, "outputs_validation", func() {
					terraformOptions := test_structure.LoadTerraformOptions(t, tempExampleFolder)
					for _, tc := range outputParameters {
						t.Run(tc.OutputVariable, func(t *testing.T) {
							ActualOutputValue := terraform.Output(t, terraformOptions, tc.OutputVariable)
							switch strings.ToLower(tc.AssertType) {
							case "equal":
								assert.Equal(t, tc.ExpectedOutputValue, ActualOutputValue)
							case "empty":
								assert.Empty(t, ActualOutputValue, tc.ExpectedOutputValue)
							case "notempty":
								assert.NotEmpty(t, ActualOutputValue)
							case "contains":
								assert.Contains(t, ActualOutputValue, tc.ExpectedOutputValue)
							}
						})
					}
				})
			})
		})
	}
}
