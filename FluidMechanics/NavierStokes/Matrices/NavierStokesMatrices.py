#> \file
#> \author Adam Reeve
#> \brief An example program to show how to obtain equation and solver
#> matrices and vectors set up by OpenCMISS.
#>
#> \section LICENSE
#>
#> Version: MPL 1.1/GPL 2.0/LGPL 2.1
#>
#> The contents of this file are subject to the Mozilla Public License
#> Version 1.1 (the "License"); you may not use this file except in
#> compliance with the License. You may obtain a copy of the License at
#> http://www.mozilla.org/MPL/
#>
#> Software distributed under the License is distributed on an "AS IS"
#> basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
#> License for the specific language governing rights and limitations
#> under the License.
#>
#> The Original Code is OpenCMISS
#>
#> The Initial Developer of the Original Code is University of Auckland,
#> Auckland, New Zealand and University of Oxford, Oxford, United
#> Kingdom. Portions created by the University of Auckland and University
#> of Oxford are Copyright (C) 2007 by the University of Auckland and
#> the University of Oxford. All Rights Reserved.
#>
#> Contributor(s):
#>
#> Alternatively, the contents of this file may be used under the terms of
#> either the GNU General Public License Version 2 or later (the "GPL"), or
#> the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
#> in which case the provisions of the GPL or the LGPL are applicable instead
#> of those above. If you wish to allow use of your version of this file only
#> under the terms of either the GPL or the LGPL, and not to allow others to
#> use your version of this file under the terms of the MPL, indicate your
#> decision by deleting the provisions above and replace them with the notice
#> and other provisions required by the GPL or the LGPL. If you do not delete
#> the provisions above, a recipient may use your version of this file under
#> the terms of any one of the MPL, the GPL or the LGPL.


#> \example FluidMechanics/NavierStokes/Matrices/NavierStokesMatrices.py
#> An example program to show how to obtain equation and solver matrices
#> and vectors set up by OpenCMISS.
#<

import sys
import os

# Add OpenCMISS python bindings directory to path so we can import it
sys.path.append(os.sep.join((
    os.environ['OPENCMISS_ROOT'], 'cm', 'bindings', 'python')))
from opencmiss import iron


# Problem parameters
numberGlobalElements = (1, 1, 1)
numberOfXi = sum(ne > 0 for ne in numberGlobalElements)
width, length, height = (float(elements) for elements in numberGlobalElements)

mu = 1.0
rho = 1.0
boundaryVelocity = (0.0, 1.0, 0.0)

startTime, stopTime, timeIncrement = 0.0, 0.4, 0.2
solverTheta = 1.0

geometryInterpolation = iron.BasisInterpolationSpecifications.QUADRATIC_LAGRANGE
velocityInterpolation = iron.BasisInterpolationSpecifications.QUADRATIC_LAGRANGE
pressureInterpolation = iron.BasisInterpolationSpecifications.LINEAR_LAGRANGE
numGauss = 3

(coordinateSystemUserNumber,
    regionUserNumber,
    generatedMeshUserNumber,
    meshUserNumber,
    decompositionUserNumber,
    geometricFieldUserNumber,
    equationsSetFieldUserNumber,
    dependentFieldUserNumber,
    materialsFieldUserNumber,
    equationsSetUserNumber,
    problemUserNumber) = range(1, 12)

# Get the computational nodes information
numberOfComputationalNodes = iron.ComputationalNumberOfNodesGet()
computationalNodeNumber = iron.ComputationalNodeNumberGet()

# Creation a rectangular cartesian coordinate system
coordinateSystem = iron.CoordinateSystem()
coordinateSystem.CreateStart(coordinateSystemUserNumber)
coordinateSystem.dimension = 3
coordinateSystem.CreateFinish()

# Create a region in the world region
region = iron.Region()
region.CreateStart(regionUserNumber, iron.WorldRegion)
region.label = "NavierStokesRegion"
region.coordinateSystem = coordinateSystem
region.CreateFinish()

# Create bases for geometry, velocity and pressure,
# reusing bases when the interpolation type is the same
def createBasis(interpolationType, basisUserNumber):
    basis = iron.Basis()
    basis.CreateStart(basisUserNumber)
    basis.type = iron.BasisTypes.LAGRANGE_HERMITE_TP
    basis.numberOfXi = numberOfXi
    basis.interpolationXi = [interpolationType] * numberOfXi
    basis.quadratureNumberOfGaussXi = [numGauss] * numberOfXi
    basis.CreateFinish()
    return basis

interpolationTypes = set((
    geometryInterpolation,
    velocityInterpolation,
    pressureInterpolation))
bases = []
interpolationMeshComponents = {}
for i, interpolationType in enumerate(interpolationTypes):
    bases.append(createBasis(
        interpolationType, i + 1))
    interpolationMeshComponents[interpolationType] = i + 1

# Create a generated regular mesh
generatedMesh = iron.GeneratedMesh()
generatedMesh.CreateStart(generatedMeshUserNumber, region)
generatedMesh.type = iron.GeneratedMeshTypes.REGULAR
generatedMesh.basis = bases
generatedMesh.extent = [width, length, height]
generatedMesh.numberOfElements = [ne for ne in numberGlobalElements if ne > 0]

mesh = iron.Mesh()
generatedMesh.CreateFinish(meshUserNumber, mesh)

# Create a decomposition for the mesh
decomposition = iron.Decomposition()
decomposition.CreateStart(decompositionUserNumber, mesh)
decomposition.type = iron.DecompositionTypes.CALCULATED
decomposition.numberOfDomains = numberOfComputationalNodes
decomposition.CreateFinish()

# Create a field for the geometry
geometricField = iron.Field()
geometricField.CreateStart(geometricFieldUserNumber, region)
geometricField.meshDecomposition = decomposition
for componentIndex in range(numberOfXi):
    geometricField.ComponentMeshComponentSet(
        iron.FieldVariableTypes.U, componentIndex + 1,
        interpolationMeshComponents[geometryInterpolation])
geometricField.CreateFinish()

# Set geometry from the generated mesh
generatedMesh.GeometricParametersCalculate(geometricField)

# Create a dynamic Navier Stokes equations set
equationsSetField = iron.Field()
equationsSet = iron.EquationsSet()
equationsSetSpecification = [iron.EquationsSetClasses.FLUID_MECHANICS,
        iron.EquationsSetTypes.NAVIER_STOKES_EQUATION,
        iron.EquationsSetSubtypes.TRANSIENT_NAVIER_STOKES]
equationsSet.CreateStart(equationsSetUserNumber, region, geometricField,
        equationsSetSpecification, equationsSetFieldUserNumber, equationsSetField)
equationsSet.CreateFinish()

# Create dependent field
dependentField = iron.Field()
equationsSet.DependentCreateStart(dependentFieldUserNumber, dependentField)
# Set velocity mesh component
for componentIndex in range(numberOfXi):
    dependentField.ComponentMeshComponentSet(
        iron.FieldVariableTypes.U, componentIndex + 1,
        interpolationMeshComponents[velocityInterpolation])
    dependentField.ComponentMeshComponentSet(
        iron.FieldVariableTypes.DELUDELN, componentIndex + 1,
        interpolationMeshComponents[velocityInterpolation])
# Set pressure mesh component
dependentField.ComponentMeshComponentSet(
    iron.FieldVariableTypes.U, numberOfXi + 1,
    interpolationMeshComponents[pressureInterpolation])
dependentField.ComponentMeshComponentSet(
    iron.FieldVariableTypes.DELUDELN, numberOfXi + 1,
    interpolationMeshComponents[pressureInterpolation])
equationsSet.DependentCreateFinish()

# Initialise dependent field
for componentIndex in range(numberOfXi):
    dependentField.ComponentValuesInitialise(
        iron.FieldVariableTypes.U, iron.FieldParameterSetTypes.VALUES,
        componentIndex + 1, 0.0)
dependentField.ComponentValuesInitialise(
    iron.FieldVariableTypes.U, iron.FieldParameterSetTypes.VALUES,
    numberOfXi + 1, 0.0)

# Create the equations set materials field variables for dynamic Navier-Stokes
materialsField = iron.Field()
equationsSet.MaterialsCreateStart(materialsFieldUserNumber, materialsField)
equationsSet.MaterialsCreateFinish()

for component, value in ((1, mu), (2, rho)):
    materialsField.ComponentValuesInitialise(
        iron.FieldVariableTypes.U,
        iron.FieldParameterSetTypes.VALUES,
        component, value)

# Create equations
equations = iron.Equations()
equationsSet.EquationsCreateStart(equations)
equations.sparsityType = iron.EquationsSparsityTypes.SPARSE
equations.lumpingType = iron.EquationsLumpingTypes.UNLUMPED
equationsSet.EquationsCreateFinish()

# Create dynamic Navier Stokes problem
problem = iron.Problem()
problemSpecification = [iron.ProblemClasses.FLUID_MECHANICS,
    iron.ProblemTypes.NAVIER_STOKES_EQUATION,
    iron.ProblemSubtypes.TRANSIENT_NAVIER_STOKES]
problem.CreateStart(problemUserNumber, problemSpecification)
problem.CreateFinish()

# Create control loops and set the time parameters
timeLoop = iron.ControlLoop()
problem.ControlLoopCreateStart()
problem.ControlLoopGet([iron.ControlLoopIdentifiers.NODE], timeLoop)
timeLoop.TimesSet(startTime, stopTime, timeIncrement)
# Disable time output as fluid_mechanics_IO_routines crashes
timeLoop.TimeOutputSet(0)
problem.ControlLoopCreateFinish()

# Create problem solvers
problem.SolversCreateStart()

# Set dynamic solver properties
dynamicSolver = iron.Solver()
dynamicSolverIndex = 1
problem.SolverGet(
    [iron.ControlLoopIdentifiers.NODE], dynamicSolverIndex, dynamicSolver)
dynamicSolver.outputType = iron.SolverOutputTypes.PROGRESS
dynamicSolver.dynamicTheta = [solverTheta]

# Set nonlinear solver properties
nonlinearSolver = iron.Solver()
dynamicSolver.DynamicNonlinearSolverGet(nonlinearSolver)
nonlinearSolver.newtonJacobianCalculationType = (
    iron.JacobianCalculationTypes.EQUATIONS)
nonlinearSolver.outputType = iron.SolverOutputTypes.NONE
nonlinearSolver.newtonAbsoluteTolerance = 1.0e-10
nonlinearSolver.newtonRelativeTolerance = 1.0e-10

# Set properties of linear solver for the nonlinear solver
linearSolver = iron.Solver()
nonlinearSolver.NewtonLinearSolverGet(linearSolver)
linearSolver.linearType = iron.LinearSolverTypes.ITERATIVE
linearSolver.linearIterativeAbsoluteTolerance = 1.0E-12
linearSolver.linearIterativeRelativeTolerance = 1.0E-12

problem.SolversCreateFinish()

# Create solver equations and add equations set to solver equations
dynamicSolver = iron.Solver()
solverEquations = iron.SolverEquations()
problem.SolverEquationsCreateStart()
problem.SolverGet([iron.ControlLoopIdentifiers.NODE], 1, dynamicSolver)
dynamicSolver.SolverEquationsGet(solverEquations)
solverEquations.sparsityType = iron.SolverEquationsSparsityTypes.SPARSE
equationsSetIndex = solverEquations.EquationsSetAdd(equationsSet)
problem.SolverEquationsCreateFinish()

# Set boundary conditions
boundaryConditions = iron.BoundaryConditions()
solverEquations.BoundaryConditionsCreateStart(boundaryConditions)

nodes = iron.Nodes()
region.NodesGet(nodes)
for node in range(1, nodes.numberOfNodes + 1):
    nodeDomain = decomposition.NodeDomainGet(
        node, interpolationMeshComponents[geometryInterpolation])
    if nodeDomain != computationalNodeNumber:
        continue
    # get x, y and z positions at node
    position = [
        geometricField.ParameterSetGetNode(
            iron.FieldVariableTypes.U, iron.FieldParameterSetTypes.VALUES,
            1, 1, node, component + 1)
        for component in range(numberOfXi)]
    tol = 1.0e-12
    if abs(position[0] - width) < tol:
        # Apply a fixed wall condition at the right side face
        for component in range(numberOfXi):
            boundaryConditions.SetNode(
                dependentField, iron.FieldVariableTypes.U,
                1, 1, node, component + 1,
                iron.BoundaryConditionsTypes.FIXED_WALL, 0.0)
    elif abs(position[0]) < tol:
        # Apply velocity conditions at the left side face
        for component, velocity in enumerate(boundaryVelocity):
            boundaryConditions.SetNode(
                dependentField, iron.FieldVariableTypes.U,
                1, 1, node, component + 1,
                iron.BoundaryConditionsTypes.FIXED_INLET, velocity)
solverEquations.BoundaryConditionsCreateFinish()

# Solve the problem
problem.Solve()

# Look at the equations matrices

# Get stiffness matrix using the dynamic type
stiffnessMatrix = iron.DistributedMatrix()
equations.DynamicMatrixGetByType(
    iron.EquationsSetDynamicMatrixTypes.STIFFNESS, stiffnessMatrix)

# Check matrix type for damping matrix using index and then get by index
assert(equations.DynamicMatrixTypeGet(2) ==
    iron.EquationsSetDynamicMatrixTypes.DAMPING)
dampingMatrix = iron.DistributedMatrix()
equations.DynamicMatrixGet(2, dampingMatrix)

# Get the equations residual vector and Jacobian matrix
residual = iron.DistributedVector()
equations.ResidualVectorGet(1, residual)
jacobian = iron.DistributedMatrix()
equations.JacobianMatrixGet(1, iron.FieldVariableTypes.U, jacobian)

# For coupled problems we can have multiple residual
# variables for a residual vector, here we just have one
numberResidualVariables = equations.ResidualNumberOfVariablesGet(1)
residualVariables = equations.ResidualVariablesGet(1, numberResidualVariables)
assert(residualVariables == [iron.FieldVariableTypes.U])

# Get the solver residual vector, right hand side vector and Jacobian matrix
solverResidual = iron.DistributedVector()
solverEquations.ResidualVectorGet(solverResidual)
residualData = solverResidual.DataGet()
print("Residual vector:")
print(residualData)
solverResidual.DataRestore(residualData)

solverRhs = iron.DistributedVector()
solverEquations.RhsVectorGet(solverRhs)
rhsData = solverRhs.DataGet()
print("RHS vector:")
print(rhsData)
solverRhs.DataRestore(rhsData)

solverJacobian = iron.DistributedMatrix()
solverEquations.JacobianMatrixGet(solverJacobian)

# Get the solver Jacobian matrix as a SciPy sparse matrix and
# calculate the matrix condition number
try:
    sparseJacobian = solverJacobian.ToSciPy()
    try:
        from scipy.sparse import linalg
        # Using SciPy's sparse eigenvalue solver we can't actually find
        # all eigenvalues and eigenvectors at once, only up to N - 1.
        # We'll just find the 6 largest and smallest eigenvalues and use
        # the largest and smallest to calculate the condition number
        eigenvalues, eigenvectors = linalg.eigs(sparseJacobian, 6, which='LM')
        maxEig = max(abs(e) for e in eigenvalues)
        eigenvalues, eigenvectors = linalg.eigs(sparseJacobian, 6, which='SM')
        minEig = min(abs(e) for e in eigenvalues)
    except AttributeError:
        # SciPy versions older than 0.9 don't have the sparse matrix
        # eigenvalue solver, so use the dense matrix.
        # This can find all eigenvalues and eigenvectors at once
        from scipy import linalg
        denseJacobian = sparseJacobian.toarray()
        eigenvalues, eigenvectors = linalg.eig(denseJacobian)
        maxEig = max(abs(e) for e in eigenvalues)
        minEig = min(abs(e) for e in eigenvalues)
    try:
        cond = maxEig / minEig
        print("Jacobian condition number: %f" % cond)
    except ZeroDivisionError:
        # If condition number is infinte we effectively have a zero row
        print("Jacobian condition number is infinte.")
    solverJacobian.SciPyRestore(sparseJacobian)
except ImportError:
    # If scipy isn't installed, just ignore this
    pass

iron.Finalise()
