# WellMate Architecture Guide

## Overview

This project follows Clean Architecture with feature-based structure.

Each feature must contain:

* data/
* domain/
* presentation/

## Layers

### 1. Presentation

* UI (pages/widgets)
* Riverpod providers
* No business logic here

### 2. Domain

* Entities
* UseCases
* Repository interfaces

### 3. Data

* API calls (Dio)
* Models
* Repository implementations

## Rules

* UI must NOT call API directly
* UI must NOT use Dio
* Providers must call UseCases
* UseCases must call Repository
* Repository connects data layer

## Example Flow

UI → Provider → UseCase → Repository → API

## Feature Rule

Each new feature must be created inside:
features/featurName/
