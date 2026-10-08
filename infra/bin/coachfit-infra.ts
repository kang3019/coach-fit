#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { CoachFitStack } from '../lib/coachfit-stack';

const app = new cdk.App();

new CoachFitStack(app, 'CoachFitStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'ap-northeast-2',
  },
  description: 'CoachFit AWS Full-Stack Architecture (EC2 + RDS PostgreSQL + Bedrock IAM) by CDK',
});
