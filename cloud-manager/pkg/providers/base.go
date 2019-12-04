package providers

import (
	"fmt"
	"github.com/aws/aws-sdk-go/service/ec2"

	"github.com/pkg/errors"
)

type Provider interface {
	TerminateInstance(string) (bool, error)
	GetName() string
	GetInstance(privateDnsName string) (*ec2.Instance, error)
}

func NewProvider(name, profile, region string) (Provider, error) {
	switch name {
	case "aws":
		return NewAwsProvider(name, profile, region)
	default:
		return nil, errors.New(fmt.Sprintf("Unsupported provider found: %s", name))
	}
}
