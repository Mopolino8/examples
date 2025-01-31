!> \file
!> \author Christian Michler, Adam Reeve
!> \brief This is an example program to solve a coupled Finite Elastiticity Darcy equation using OpenCMISS calls.
!>
!> \section LICENSE
!>
!> Version: MPL 1.1/GPL 2.0/LGPL 2.1
!>
!> The contents of this file are subject to the Mozilla Public License
!> Version 1.1 (the "License"); you may not use this file except in
!> compliance with the License. You may obtain a copy of the License at
!> http://www.mozilla.org/MPL/
!>
!> Software distributed under the License is distributed on an "AS IS"
!> basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
!> License for the specific language governing rights and limitations
!> under the License.
!>
!> The Original Code is OpenCMISS
!>
!> The Initial Developer of the Original Code is University of Auckland,
!> Auckland, New Zealand and University of Oxford, Oxford, United
!> Kingdom. Portions created by the University of Auckland and University
!> of Oxford are Copyright (C) 2007 by the University of Auckland and
!> the University of Oxford. All Rights Reserved.
!>
!> Contributor(s):
!>
!> Alternatively, the contents of this file may be used under the terms of
!> either the GNU General Public License Version 2 or later (the "GPL"), or
!> the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
!> in which case the provisions of the GPL or the LGPL are applicable instead
!> of those above. If you wish to allow use of your version of this file only
!> under the terms of either the GPL or the LGPL, and not to allow others to
!> use your version of this file under the terms of the MPL, indicate your
!> decision by deleting the provisions above and replace them with the notice
!> and other provisions required by the GPL or the LGPL. If you do not delete
!> the provisions above, a recipient may use your version of this file under
!> the terms of any one of the MPL, the GPL or the LGPL.
!>

!> \example MultiPhysics/Poroelasticity/FiniteElasticityDarcy/IncompressibleElasticityDrivenDarcy/src/IncompressibleElasticityDrivenDarcyExample.f90
!! Example program to solve coupled FiniteElasticityDarcy equations using OpenCMISS calls.
!! \par Latest Builds:
!! \li <a href='http://autotest.bioeng.auckland.ac.nz/opencmiss-build/logs_x86_64-linux/MultiPhysics/Poroelasticity/FiniteElasticityDarcy/IncompressibleElasticityDrivenDarcy/build-intel'>Linux Intel Build</a>
!! \li <a href='http://autotest.bioeng.auckland.ac.nz/opencmiss-build/logs_x86_64-linux/MultiPhysics/Poroelasticity/FiniteElasticityDarcy/IncompressibleElasticityDrivenDarcy/build-intel'>Linux GNU Build</a>
!!
!<

! !
! !  This example considers a coupled Finite Elasticity Darcy problem
! !

!> Main program

PROGRAM FINITEELASTICITYDARCYIOEXAMPLE

  !
  !================================================================================================================================
  !

  !PROGRAM LIBRARIES

  USE OpenCMISS
  USE OpenCMISS_Iron
  USE IOSTUFF
#ifndef NOMPIMOD
  USE MPI
#endif

#ifdef WIN32
  USE IFQWINCMISS
#endif

  !
  !================================================================================================================================
  !

  !PROGRAM VARIABLES AND TYPES

  IMPLICIT NONE

#ifdef NOMPIMOD
#include "mpif.h"
#endif


  !Test program parameters

  REAL(CMISSRP), PARAMETER :: Y_DIM=1.0_CMISSRP
  REAL(CMISSRP), PARAMETER :: X_DIM=1.0_CMISSRP
  REAL(CMISSRP), PARAMETER :: Z_DIM=1.0_CMISSRP

  INTEGER(CMISSIntg), PARAMETER :: LinearBasisUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: QuadraticBasisUserNumber=2
  INTEGER(CMISSIntg), PARAMETER :: CubicBasisUserNumber=3

  INTEGER(CMISSIntg), PARAMETER :: CoordinateSystemUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: RegionUserNumber=2
  INTEGER(CMISSIntg), PARAMETER :: MeshUserNumber=3
  INTEGER(CMISSIntg), PARAMETER :: DecompositionUserNumber=4
  INTEGER(CMISSIntg), PARAMETER :: GeometricFieldUserNumber=5
  INTEGER(CMISSIntg), PARAMETER :: MaterialsFieldUserNumberDarcy=8
  INTEGER(CMISSIntg), PARAMETER :: EquationsSetUserNumberDarcy=12
  INTEGER(CMISSIntg), PARAMETER :: ProblemUserNumber=14
  INTEGER(CMISSIntg), PARAMETER :: EquationsSetFieldUserNumberDarcy=22

  INTEGER(CMISSIntg), PARAMETER :: ControlLoopSolidNumber=1
  INTEGER(CMISSIntg), PARAMETER :: ControlLoopFluidNumber=2
  INTEGER(CMISSIntg), PARAMETER :: ControlLoopSubiterationNumber=1
  INTEGER(CMISSIntg), PARAMETER :: SolverSolidIndex=1
  INTEGER(CMISSIntg), PARAMETER :: SolverDarcyIndex=1
  INTEGER(CMISSIntg), PARAMETER :: MaterialsFieldUserNumberDarcyPorosity=1
  INTEGER(CMISSIntg), PARAMETER :: MaterialsFieldUserNumberDarcyPermOverVis=2

  INTEGER(CMISSIntg), PARAMETER :: FieldGeometryNumberOfVariables=1
  INTEGER(CMISSIntg), PARAMETER :: FieldGeometryNumberOfComponents=3

  !Program types

  !Program variables

  INTEGER(CMISSIntg) :: NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS,NUMBER_GLOBAL_Z_ELEMENTS

!   INTEGER(CMISSIntg) :: MPI_IERROR
  INTEGER(CMISSIntg) :: NumberOfComputationalNodes,NumberOfDomains,ComputationalNodeNumber

  INTEGER(CMISSIntg) :: NUMBER_OF_DIMENSIONS

  INTEGER(CMISSIntg) :: MAXIMUM_ITERATIONS
  INTEGER(CMISSIntg) :: RESTART_VALUE

  INTEGER(CMISSIntg) :: EQUATIONS_DARCY_OUTPUT
  INTEGER(CMISSIntg) :: COMPONENT_NUMBER, NODE_NUMBER

  INTEGER(CMISSIntg) :: DYNAMIC_SOLVER_DARCY_OUTPUT_FREQUENCY
  INTEGER(CMISSIntg) :: DYNAMIC_SOLVER_DARCY_OUTPUT_TYPE
  INTEGER(CMISSIntg) :: LINEAR_SOLVER_DARCY_OUTPUT_TYPE
  INTEGER(CMISSIntg) :: LINEAR_SOLVER_MAT_PROPERTIES_OUTPUT_TYPE

  REAL(CMISSRP) :: GEOMETRY_TOLERANCE
  INTEGER(CMISSIntg) :: BASIS_XI_INTERPOLATION_SOLID
  REAL(CMISSRP) :: INITIAL_FIELD_DARCY(4)
  REAL(CMISSRP) :: DIVERGENCE_TOLERANCE
  REAL(CMISSRP) :: RELATIVE_TOLERANCE
  REAL(CMISSRP) :: ABSOLUTE_TOLERANCE
  REAL(CMISSRP) :: LINESEARCH_ALPHA
  REAL(CMISSRP) :: VALUE
  REAL(CMISSRP) :: POROSITY_PARAM_DARCY, PERM_OVER_VIS_PARAM_DARCY
  REAL(CMISSRP) :: INNER_PRESSURE,OUTER_PRESSURE

  LOGICAL :: EXPORT_FIELD_IO
  LOGICAL :: LINEAR_SOLVER_DARCY_DIRECT_FLAG

  !CMISS variables

  !Regions
  TYPE(cmfe_RegionType) :: Region
  TYPE(cmfe_RegionType) :: WorldRegion
  !Coordinate systems
  TYPE(cmfe_CoordinateSystemType) :: CoordinateSystem
  TYPE(cmfe_CoordinateSystemType) :: WorldCoordinateSystem
  !Basis
!   TYPE(cmfe_BasisType) :: CubicBasis, QuadraticBasis, LinearBasis, Bases(2)
  TYPE(cmfe_BasisType),allocatable :: Bases(:)
  !Meshes
  TYPE(cmfe_MeshType) :: Mesh
  TYPE(cmfe_GeneratedMeshType) :: GeneratedMesh

  !Decompositions
  TYPE(cmfe_DecompositionType) :: Decomposition
  !Fields
  TYPE(cmfe_FieldsType) :: Fields
  !Field types
  TYPE(cmfe_FieldType) :: GeometricField
  TYPE(cmfe_FieldType) :: MaterialsFieldDarcy
  TYPE(cmfe_FieldType) :: EquationsSetFieldDarcy
  !Boundary conditions
  TYPE(cmfe_BoundaryConditionsType) :: BoundaryConditionsDarcy
  !Equations sets
  TYPE(cmfe_EquationsSetType) :: EquationsSetDarcy
  !Equations
  TYPE(cmfe_EquationsType) :: EquationsDarcy
  !Problems
  TYPE(cmfe_ProblemType) :: Problem
  !Control loops
  TYPE(cmfe_ControlLoopType) :: ControlLoop
  !Solvers
  TYPE(cmfe_SolverType) :: DynamicSolverDarcy
  TYPE(cmfe_SolverType) :: LinearSolverDarcy
  TYPE(cmfe_SolverType) :: LinearSolverSolid
  !Solver equations
  TYPE(cmfe_SolverEquationsType) :: SolverEquationsDarcy
  ! nodes and elements
  TYPE(cmfe_NodesType) :: Nodes
  TYPE(cmfe_MeshElementsType),allocatable :: Elements(:)

  !Other variables
  INTEGER(CMISSIntg),ALLOCATABLE,TARGET :: Face1Nodes(:),Face2Nodes(:)
  INTEGER(CMISSIntg),ALLOCATABLE,TARGET :: Face3Nodes(:),Face4Nodes(:)
  INTEGER(CMISSIntg),ALLOCATABLE,TARGET :: Face5Nodes(:),Face6Nodes(:)
  INTEGER(CMISSIntg),ALLOCATABLE,TARGET :: Face7Nodes(:),Face8Nodes(:)
  INTEGER(CMISSIntg),ALLOCATABLE,TARGET :: Face9Nodes(:),Face10Nodes(:)
  INTEGER(CMISSIntg),ALLOCATABLE,TARGET :: Face11Nodes(:),Face12Nodes(:)
  INTEGER(CMISSIntg) :: FaceXi(6)
  INTEGER(CMISSIntg) :: NN,NODE,NodeDomain
  REAL(CMISSRP) :: XCoord,YCoord,ZCoord
  LOGICAL :: X_FIXED,Y_FIXED,X_OKAY,Y_OKAY

#ifdef WIN32
  !Quickwin type
  LOGICAL :: QUICKWIN_STATUS=.FALSE.
  TYPE(WINDOWCONFIG) :: QUICKWIN_WINDOW_CONFIG
#endif

  !Generic CMISS variables

  INTEGER(CMISSIntg) :: EquationsSetIndex
  INTEGER(CMISSIntg) :: Err


  INTEGER(CMISSIntg) :: DIAG_LEVEL_LIST(5)
!   CHARACTER(LEN=255) :: DIAG_ROUTINE_LIST(8) !,TIMING_ROUTINE_LIST(1)
  CHARACTER(LEN=255) :: DIAG_ROUTINE_LIST(1) !,TIMING_ROUTINE_LIST(1)

  !
  !--------------------------------------------------------------------------------------------------------------------------------
  !

  !Program variables and types (finite elasticity part)

  !Test program parameters

  INTEGER(CMISSIntg) :: SolidMeshComponenetNumber

  INTEGER(CMISSIntg), PARAMETER :: FieldGeometrySolidUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: FieldGeometrySolidNumberOfVariables=1
  INTEGER(CMISSIntg), PARAMETER :: FieldGeometrySolidNumberOfComponents=3

  INTEGER(CMISSIntg), PARAMETER :: FieldFibreSolidUserNumber=2
  INTEGER(CMISSIntg), PARAMETER :: FieldFibreSolidNumberOfVariables=1
  INTEGER(CMISSIntg), PARAMETER :: FieldFibreSolidNumberOfComponents=3

  INTEGER(CMISSIntg), PARAMETER :: FieldMaterialSolidUserNumber=3
  INTEGER(CMISSIntg), PARAMETER :: FieldMaterialSolidNumberOfVariables=1
  INTEGER(CMISSIntg), PARAMETER :: FieldMaterialSolidNumberOfComponents=3

  INTEGER(CMISSIntg), PARAMETER :: FieldDependentSolidUserNumber=4
  INTEGER(CMISSIntg), PARAMETER :: FieldDependentSolidNumberOfVariables=4
  INTEGER(CMISSIntg), PARAMETER :: FieldDependentSolidNumberOfComponents=4
  INTEGER(CMISSIntg), PARAMETER :: FieldDependentFluidNumberOfComponents=4  !(u,v,w,m)

  INTEGER(CMISSIntg), PARAMETER :: IndependentFieldDarcyUserNumber=15

  INTEGER(CMISSIntg), PARAMETER :: EquationSetSolidUserNumber=1
  INTEGER(CMISSIntg), PARAMETER :: EquationsSetFieldSolidUserNumber=25

  INTEGER(CMISSIntg), PARAMETER :: SolidDisplMeshComponentNumber=1
  INTEGER(CMISSIntg), PARAMETER :: SolidLagrMultMeshComponentNumber=2
  INTEGER(CMISSIntg), PARAMETER :: SolidGeometryMeshComponentNumber=SolidDisplMeshComponentNumber

  INTEGER(CMISSIntg), PARAMETER :: DarcyVelMeshComponentNumber=SolidLagrMultMeshComponentNumber
  INTEGER(CMISSIntg), PARAMETER :: DarcyMassIncreaseMeshComponentNumber=SolidLagrMultMeshComponentNumber
!   INTEGER(CMISSIntg), PARAMETER :: DarcyGeometryMeshComponentNumber=SolidDisplMeshComponentNumber

  INTEGER(CMISSIntg), PARAMETER :: GeneratedMeshUserNumber=32
  !Program types
  !Program variables

  REAL(CMISSRP) :: DYNAMIC_SOLVER_DARCY_START_TIME
  REAL(CMISSRP) :: DYNAMIC_SOLVER_DARCY_STOP_TIME
  REAL(CMISSRP) :: DYNAMIC_SOLVER_DARCY_THETA
  REAL(CMISSRP) :: DYNAMIC_SOLVER_DARCY_TIME_INCREMENT

  !CMISS variables

  TYPE(cmfe_BoundaryConditionsType) :: BoundaryConditionsSolid
  TYPE(cmfe_EquationsType) :: EquationsSolid
  TYPE(cmfe_EquationsSetType) :: EquationsSetSolid
  TYPE(cmfe_FieldType) :: GeometricFieldSolid,FibreFieldSolid,MaterialFieldSolid
  TYPE(cmfe_FieldType) :: DependentFieldSolid,EquationsSetFieldSolid
  TYPE(cmfe_FieldType) :: IndependentFieldDarcy
  TYPE(cmfe_SolverType) :: SolverSolid
  TYPE(cmfe_SolverEquationsType) :: SolverEquationsSolid

  INTEGER(CMISSIntg),allocatable :: surface_lin_inner(:),surface_lin_outer(:),surface_lin_base(:)
  INTEGER(CMISSIntg),allocatable :: surface_quad_inner(:),surface_quad_outer(:),surface_quad_base(:)

  !End - Program variables and types (finite elasticity part)

  !
  !--------------------------------------------------------------------------------------------------------------------------------
  !


#ifdef WIN32
  !Initialise QuickWin
  QUICKWIN_WINDOW_CONFIG%TITLE="General Output" !Window title
  QUICKWIN_WINDOW_CONFIG%NUMTEXTROWS=-1 !Max possible number of rows
  QUICKWIN_WINDOW_CONFIG%MODE=QWIN$SCROLLDOWN
  !Set the window parameters
  QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
  !If attempt fails set with system estimated values
  IF(.NOT.QUICKWIN_STATUS) QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
#endif

  !
  !================================================================================================================================
  !
  NUMBER_GLOBAL_X_ELEMENTS=1
  NUMBER_GLOBAL_Y_ELEMENTS=1
  NUMBER_GLOBAL_Z_ELEMENTS=3

  IF(NUMBER_GLOBAL_Z_ELEMENTS==0)THEN
    NUMBER_OF_DIMENSIONS=2
  ELSE
    NUMBER_OF_DIMENSIONS=3
  ENDIF
  !PROBLEM CONTROL PANEL

!   BASIS_XI_INTERPOLATION_SOLID=CMFE_BASIS_LINEAR_LAGRANGE_INTERPOLATION
  BASIS_XI_INTERPOLATION_SOLID=CMFE_BASIS_QUADRATIC_LAGRANGE_INTERPOLATION
  !Set geometric tolerance
  GEOMETRY_TOLERANCE = 1.0E-12_CMISSRP
  !Set initial values
  INITIAL_FIELD_DARCY(1)=0.0_CMISSRP
  INITIAL_FIELD_DARCY(2)=0.0_CMISSRP
  INITIAL_FIELD_DARCY(3)=0.0_CMISSRP
  INITIAL_FIELD_DARCY(4)=0.0_CMISSRP
  !Set material parameters
  POROSITY_PARAM_DARCY=0.1_CMISSRP
  PERM_OVER_VIS_PARAM_DARCY=1.0_CMISSRP
  !Set output parameter
  !(NoOutput/ProgressOutput/TimingOutput/SolverOutput/SolverMatrixOutput)
  DYNAMIC_SOLVER_DARCY_OUTPUT_TYPE=CMFE_SOLVER_PROGRESS_OUTPUT
  LINEAR_SOLVER_DARCY_OUTPUT_TYPE=CMFE_SOLVER_SOLVER_OUTPUT
  !(NoOutput/TimingOutput/MatrixOutput/ElementOutput)
  EQUATIONS_DARCY_OUTPUT=CMFE_EQUATIONS_NO_OUTPUT

  !Set time parameter
  DYNAMIC_SOLVER_DARCY_START_TIME=0.0_CMISSRP
  DYNAMIC_SOLVER_DARCY_TIME_INCREMENT=1.0e-4_CMISSRP
  DYNAMIC_SOLVER_DARCY_STOP_TIME=100_CMISSIntg * DYNAMIC_SOLVER_DARCY_TIME_INCREMENT
  DYNAMIC_SOLVER_DARCY_THETA=1.0_CMISSRP !2.0_CMISSRP/3.0_CMISSRP
  !Set result output parameter
  DYNAMIC_SOLVER_DARCY_OUTPUT_FREQUENCY=1
  !Set solver parameters
  LINEAR_SOLVER_DARCY_DIRECT_FLAG=.TRUE.
  RELATIVE_TOLERANCE=1.0E-10_CMISSRP !default: 1.0E-05_CMISSRP
  ABSOLUTE_TOLERANCE=1.0E-10_CMISSRP !default: 1.0E-10_CMISSRP
  DIVERGENCE_TOLERANCE=1.0E5_CMISSRP !default: 1.0E5
  MAXIMUM_ITERATIONS=10000_CMISSIntg !default: 100000
  RESTART_VALUE=30_CMISSIntg !default: 30
  LINESEARCH_ALPHA=1.0_CMISSRP


  !
  !================================================================================================================================
  !

  !INITIALISE OPENCMISS

  CALL cmfe_Initialise(WorldCoordinateSystem,WorldRegion,Err)

  CALL cmfe_ErrorHandlingModeSet(CMFE_ERRORS_TRAP_ERROR,Err)

  !
  !================================================================================================================================
  !

  !Set diagnostics

  DIAG_LEVEL_LIST(1)=1
  DIAG_LEVEL_LIST(2)=2
  DIAG_LEVEL_LIST(3)=3
  DIAG_LEVEL_LIST(4)=4
  DIAG_LEVEL_LIST(5)=5

  DIAG_ROUTINE_LIST(1)="WRITE_IP_INFO"
!   DIAG_ROUTINE_LIST(2)="FINITE_ELASTICITY_GAUSS_CAUCHY_TENSOR"

  !CMFE_ALL_DIAG_TYPE/CMFE_IN_DIAG_TYPE/CMFE_FROM_DIAG_TYPE
  CALL cmfe_DiagnosticsSetOn(CMFE_IN_DIAG_TYPE,DIAG_LEVEL_LIST,"Diagnostics",DIAG_ROUTINE_LIST,Err)

  !CMFE_ALL_TIMING_TYPE/CMFE_IN_TIMING_TYPE/CMFE_FROM_TIMING_TYPE
  !TIMING_ROUTINE_LIST(1)="PROBLEM_FINITE_ELEMENT_CALCULATE"
  !CALL TIMING_SET_ON(IN_TIMING_TYPE,.TRUE.,"",TIMING_ROUTINE_LIST,ERR,ERROR,*999)

  !
  !================================================================================================================================
  !

  !Get the number of computational nodes and this computational node number
  CALL cmfe_ComputationalNumberOfNodesGet(NumberOfComputationalNodes,Err)
  CALL cmfe_ComputationalNodeNumberGet(ComputationalNodeNumber,Err)

  NumberOfDomains = NumberOfComputationalNodes
  write(*,*) "NumberOfDomains = ",NumberOfDomains

  !
  !================================================================================================================================
  !

  !COORDINATE SYSTEM

  CALL cmfe_CoordinateSystem_Initialise(CoordinateSystem,Err)
  CALL cmfe_CoordinateSystem_CreateStart(CoordinateSystemUserNumber,CoordinateSystem,Err)
  CALL cmfe_CoordinateSystem_DimensionSet(CoordinateSystem,NUMBER_OF_DIMENSIONS,Err)
  CALL cmfe_CoordinateSystem_CreateFinish(CoordinateSystem,Err)

  !
  !================================================================================================================================
  !

  !REGION
  !For a volume-coupled problem, solid and fluid are based in the same region

  CALL cmfe_Region_Initialise(Region,Err)
  CALL cmfe_Region_CreateStart(RegionUserNumber,WorldRegion,Region,Err)
  CALL cmfe_Region_CoordinateSystemSet(Region,CoordinateSystem,Err)
  CALL cmfe_Region_CreateFinish(Region,Err)

  !
  !================================================================================================================================
  !

call READ_MESH('input/pigheart-mesh',MeshUserNumber,Region, Mesh,Bases,Nodes,Elements)
!   !BASES
!   !Define basis functions
!   CALL cmfe_Basis_Initialise(LinearBasis,Err)
!   CALL cmfe_Basis_CreateStart(LinearBasisUserNumber,LinearBasis,Err)
!   CALL cmfe_Basis_QuadratureNumberOfGaussXiSet(LinearBasis, &
!     & [CMFE_BASIS_HIGH_QUADRATURE_SCHEME,CMFE_BASIS_HIGH_QUADRATURE_SCHEME,CMFE_BASIS_HIGH_QUADRATURE_SCHEME],Err)
!   !CALL cmfe_Basis_QuadratureLocalFaceGaussEvaluateSet(LinearBasis,.true.,Err)
!   CALL cmfe_Basis_CreateFinish(LinearBasis,Err)
! 
!   CALL cmfe_Basis_Initialise(QuadraticBasis,Err)
!   CALL cmfe_Basis_CreateStart(QuadraticBasisUserNumber,QuadraticBasis,Err)
!   CALL cmfe_Basis_InterpolationXiSet(QuadraticBasis,[CMFE_BASIS_QUADRATIC_LAGRANGE_INTERPOLATION, &
!     & CMFE_BASIS_QUADRATIC_LAGRANGE_INTERPOLATION,CMFE_BASIS_QUADRATIC_LAGRANGE_INTERPOLATION],Err)
!   CALL cmfe_Basis_QuadratureNumberOfGaussXiSet(QuadraticBasis, &
!     & [CMFE_BASIS_HIGH_QUADRATURE_SCHEME,CMFE_BASIS_HIGH_QUADRATURE_SCHEME,CMFE_BASIS_HIGH_QUADRATURE_SCHEME],Err)
!   !CALL cmfe_Basis_QuadratureLocalFaceGaussEvaluateSet(QuadraticBasis,.true.,Err)
!   CALL cmfe_Basis_CreateFinish(QuadraticBasis,Err)
! 
!   CALL cmfe_Basis_Initialise(CubicBasis,Err)
!   CALL cmfe_Basis_CreateStart(CubicBasisUserNumber,CubicBasis,Err)
!   CALL cmfe_Basis_InterpolationXiSet(CubicBasis,[CMFE_BASIS_CUBIC_LAGRANGE_INTERPOLATION, &
!     & CMFE_BASIS_CUBIC_LAGRANGE_INTERPOLATION,CMFE_BASIS_CUBIC_LAGRANGE_INTERPOLATION],Err)
!   CALL cmfe_Basis_QuadratureNumberOfGaussXiSet(CubicBasis, &
!     & [CMFE_BASIS_HIGH_QUADRATURE_SCHEME,CMFE_BASIS_HIGH_QUADRATURE_SCHEME,CMFE_BASIS_HIGH_QUADRATURE_SCHEME],Err)
!   !CALL cmfe_Basis_QuadratureLocalFaceGaussEvaluateSet(CubicBasis,.true.,Err) !Enable 3D interpolation on faces
!   CALL cmfe_Basis_CreateFinish(CubicBasis,Err)
! 
!   !LinearBasis/QuadraticBasis/CubicBasis
!   Bases(1)=QuadraticBasis
!   Bases(2)=LinearBasis
! 
!   !Start the creation of a generated mesh in the region
!   CALL cmfe_GeneratedMesh_Initialise(GeneratedMesh,Err)
!   CALL cmfe_GeneratedMesh_CreateStart(GeneratedMeshUserNumber,Region,GeneratedMesh,Err)
!   CALL cmfe_GeneratedMesh_TypeSet(GeneratedMesh,CMFE_GENERATED_MESH_REGULAR_MESH_TYPE,Err)
!   CALL cmfe_GeneratedMesh_BasisSet(GeneratedMesh,Bases,Err)
!   IF(NUMBER_GLOBAL_Z_ELEMENTS==0) THEN
!     CALL cmfe_GeneratedMesh_ExtentSet(GeneratedMesh,[X_DIM,Y_DIM],Err)
!     CALL cmfe_GeneratedMesh_NumberOfElementsSet(GeneratedMesh,[NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS],Err)
!   ELSE
!     CALL cmfe_GeneratedMesh_ExtentSet(GeneratedMesh,[X_DIM,Y_DIM,Z_DIM],Err)
!     CALL cmfe_GeneratedMesh_NumberOfElementsSet(GeneratedMesh,[NUMBER_GLOBAL_X_ELEMENTS,NUMBER_GLOBAL_Y_ELEMENTS, &
!       & NUMBER_GLOBAL_Z_ELEMENTS],Err)
!   ENDIF
!   CALL cmfe_Mesh_Initialise(Mesh,Err)
!   CALL cmfe_GeneratedMesh_CreateFinish(GeneratedMesh,MeshUserNumber,Mesh,Err)
! -------------------------------------------------------------------------------
  

  !GEOMETRIC FIELD

  !Create a decomposition:
  CALL cmfe_Decomposition_Initialise(Decomposition,Err)
  CALL cmfe_Decomposition_CreateStart(DecompositionUserNumber,Mesh,Decomposition,Err)
  !Set the decomposition to be a general decomposition with the specified number of domains
  CALL cmfe_Decomposition_TypeSet(Decomposition,CMFE_DECOMPOSITION_CALCULATED_TYPE,Err)
  CALL cmfe_Decomposition_NumberOfDomainsSet(Decomposition,NumberOfDomains,Err)
  CALL cmfe_Decomposition_CalculateFacesSet(Decomposition,.true.,Err)
  CALL cmfe_Decomposition_CreateFinish(Decomposition,Err)

  CALL cmfe_Field_Initialise(GeometricField,Err)
  CALL cmfe_Field_CreateStart(GeometricFieldUserNumber,Region,GeometricField,Err)
  CALL cmfe_Field_MeshDecompositionSet(GeometricField,Decomposition,Err)
  CALL cmfe_Field_TypeSet(GeometricField,CMFE_FIELD_GEOMETRIC_TYPE,Err)
  CALL cmfe_Field_NumberOfVariablesSet(GeometricField,FieldGeometryNumberOfVariables,Err)
  CALL cmfe_Field_NumberOfComponentsSet(GeometricField,CMFE_FIELD_U_VARIABLE_TYPE,3,Err)  
  CALL cmfe_Field_ComponentMeshComponentSet(GeometricField,CMFE_FIELD_U_VARIABLE_TYPE,1,SolidGeometryMeshComponentNumber,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(GeometricField,CMFE_FIELD_U_VARIABLE_TYPE,2,SolidGeometryMeshComponentNumber,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(GeometricField,CMFE_FIELD_U_VARIABLE_TYPE,3,SolidGeometryMeshComponentNumber,Err)
  CALL cmfe_Field_CreateFinish(GeometricField,Err)
CALL READ_NODES('input/pigheart-nodes',GeometricField)
!   CALL cmfe_GeneratedMesh_GeometricParametersCalculate(GeneratedMesh,GeometricField,Err)

  !--------------------------------------------------------------------------------------------------------------------------------
  ! Solid

  !Create a decomposition

  !Create a field to put the geometry (defualt is geometry)

  SolidMeshComponenetNumber = SolidGeometryMeshComponentNumber

  CALL cmfe_Field_Initialise(GeometricFieldSolid,Err)
  CALL cmfe_Field_CreateStart(FieldGeometrySolidUserNumber,Region,GeometricFieldSolid,Err)
  CALL cmfe_Field_MeshDecompositionSet(GeometricFieldSolid,Decomposition,Err)
  CALL cmfe_Field_TypeSet(GeometricFieldSolid,CMFE_FIELD_GEOMETRIC_TYPE,Err)
  CALL cmfe_Field_NumberOfVariablesSet(GeometricFieldSolid,FieldGeometrySolidNumberOfVariables,Err)
  CALL cmfe_Field_NumberOfComponentsSet(GeometricFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,FieldGeometrySolidNumberOfComponents,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(GeometricFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,1,SolidMeshComponenetNumber,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(GeometricFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,2,SolidMeshComponenetNumber,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(GeometricFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,3,SolidMeshComponenetNumber,Err)
  CALL cmfe_Field_CreateFinish(GeometricFieldSolid,Err)
  !Set the mesh component to be used by the field components.
CALL READ_NODES('input/pigheart-nodes',GeometricFieldSolid)
!  CALL cmfe_GeneratedMesh_GeometricParametersCalculate(GeneratedMesh,GeometricFieldSolid,Err)

  !Create a fibre field and attach it to the geometric field
  CALL cmfe_Field_Initialise(FibreFieldSolid,Err)
  CALL cmfe_Field_CreateStart(FieldFibreSolidUserNumber,Region,FibreFieldSolid,Err)
  CALL cmfe_Field_TypeSet(FibreFieldSolid,CMFE_FIELD_FIBRE_TYPE,Err)
  CALL cmfe_Field_MeshDecompositionSet(FibreFieldSolid,Decomposition,Err)
  CALL cmfe_Field_GeometricFieldSet(FibreFieldSolid,GeometricFieldSolid,Err)
  CALL cmfe_Field_NumberOfVariablesSet(FibreFieldSolid,FieldFibreSolidNumberOfVariables,Err)
  CALL cmfe_Field_NumberOfComponentsSet(FibreFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,FieldFibreSolidNumberOfComponents,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(FibreFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,1,SolidGeometryMeshComponentNumber,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(FibreFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,2,SolidGeometryMeshComponentNumber,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(FibreFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,3,SolidGeometryMeshComponentNumber,Err)
  CALL cmfe_Field_CreateFinish(FibreFieldSolid,Err)

  ! end Solid
  !--------------------------------------------------------------------------------------------------------------------------------

  !
  !================================================================================================================================
  !

  !EQUATIONS SETS

  !Create the equations set for ALE Darcy
  CALL cmfe_Field_Initialise(EquationsSetFieldDarcy,Err)
  CALL cmfe_EquationsSet_Initialise(EquationsSetDarcy,Err)
  CALL cmfe_EquationsSet_CreateStart(EquationsSetUserNumberDarcy,Region,GeometricField,[CMFE_EQUATIONS_SET_FLUID_MECHANICS_CLASS, &
    & CMFE_EQUATIONS_SET_DARCY_EQUATION_TYPE,CMFE_EQUATIONS_SET_INCOMPRESS_ELASTICITY_DRIVEN_DARCY_SUBTYPE], &
    & EquationsSetFieldUserNumberDarcy,EquationsSetFieldDarcy,EquationsSetDarcy,Err)
  CALL cmfe_EquationsSet_CreateFinish(EquationsSetDarcy,Err)

  !Create the equations set for the solid
  CALL cmfe_Field_Initialise(EquationsSetFieldSolid,Err)
  CALL cmfe_EquationsSet_Initialise(EquationsSetSolid,Err)
  CALL cmfe_EquationsSet_CreateStart(EquationSetSolidUserNumber,Region,FibreFieldSolid,[CMFE_EQUATIONS_SET_ELASTICITY_CLASS, &
    & CMFE_EQUATIONS_SET_FINITE_ELASTICITY_TYPE,CMFE_EQUATIONS_SET_INCOMPRESS_ELASTICITY_DRIVEN_DARCY_SUBTYPE], &
    & EquationsSetFieldSolidUserNumber,EquationsSetFieldSolid,EquationsSetSolid,Err)
  CALL cmfe_EquationsSet_CreateFinish(EquationsSetSolid,Err)

  !--------------------------------------------------------------------------------------------------------------------------------
  ! Solid Materials Field

  !Create a material field and attach it to the geometric field
  CALL cmfe_Field_Initialise(MaterialFieldSolid,Err)
  !
  CALL cmfe_Field_CreateStart(FieldMaterialSolidUserNumber,Region,MaterialFieldSolid,Err)
  !
  CALL cmfe_Field_TypeSet(MaterialFieldSolid,CMFE_FIELD_MATERIAL_TYPE,Err)
  CALL cmfe_Field_MeshDecompositionSet(MaterialFieldSolid,Decomposition,Err)
  CALL cmfe_Field_GeometricFieldSet(MaterialFieldSolid,GeometricFieldSolid,Err)
  CALL cmfe_Field_NumberOfVariablesSet(MaterialFieldSolid,FieldMaterialSolidNumberOfVariables,Err)
  CALL cmfe_Field_NumberOfComponentsSet(MaterialFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,FieldMaterialSolidNumberOfComponents,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(MaterialFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,1,SolidGeometryMeshComponentNumber,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(MaterialFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,2,SolidGeometryMeshComponentNumber,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(MaterialFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,3,SolidGeometryMeshComponentNumber,Err)
  !
  CALL cmfe_Field_CreateFinish(MaterialFieldSolid,Err)

  !Set material parameters
  CALL cmfe_Field_ComponentValuesInitialise(MaterialFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,1, &
    & 2.0_CMISSRP,Err)
!   CALL cmfe_Field_ComponentValuesInitialise(MaterialFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,1,2.0e3_CMISSRP,Err)
  CALL cmfe_Field_ComponentValuesInitialise(MaterialFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,2, &
    & 6.0_CMISSRP,Err)
!   CALL cmfe_Field_ComponentValuesInitialise(MaterialFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,2,33.0_CMISSRP,Err)
  CALL cmfe_Field_ComponentValuesInitialise(MaterialFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,3, &
    & 10.0_CMISSRP,Err)


  CALL cmfe_EquationsSet_MaterialsCreateStart(EquationsSetSolid,FieldMaterialSolidUserNumber,MaterialFieldSolid,Err)
  CALL cmfe_EquationsSet_MaterialsCreateFinish(EquationsSetSolid,Err)

  ! end Solid
  !--------------------------------------------------------------------------------------------------------------------------------


  !
  !================================================================================================================================
  !

  !DEPENDENT FIELDS

  !--------------------------------------------------------------------------------------------------------------------------------
  ! Solid

  !Create a dependent field with four variables (U, DelUDelN = solid, V, DelVDelN = Darcy) and four components
  CALL cmfe_Field_Initialise(DependentFieldSolid,Err)
  !
  CALL cmfe_Field_CreateStart(FieldDependentSolidUserNumber,Region,DependentFieldSolid,Err)
  !
  CALL cmfe_Field_TypeSet(DependentFieldSolid,CMFE_FIELD_GENERAL_TYPE,Err)
  CALL cmfe_Field_MeshDecompositionSet(DependentFieldSolid,Decomposition,Err)
  CALL cmfe_Field_GeometricFieldSet(DependentFieldSolid,GeometricFieldSolid,Err)
  CALL cmfe_Field_DependentTypeSet(DependentFieldSolid,CMFE_FIELD_DEPENDENT_TYPE,Err)
  CALL cmfe_Field_NumberOfVariablesSet(DependentFieldSolid,FieldDependentSolidNumberOfVariables,Err)
  CALL cmfe_Field_VariableTypesSet(DependentFieldSolid,[CMFE_FIELD_U_VARIABLE_TYPE, &
    & CMFE_FIELD_DELUDELN_VARIABLE_TYPE,CMFE_FIELD_V_VARIABLE_TYPE,CMFE_FIELD_DELVDELN_VARIABLE_TYPE],Err)
  CALL cmfe_Field_NumberOfComponentsSet(DependentFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,FieldDependentSolidNumberOfComponents,Err)
  CALL cmfe_Field_NumberOfComponentsSet(DependentFieldSolid,CMFE_FIELD_DELUDELN_VARIABLE_TYPE, &
    & FieldDependentSolidNumberOfComponents,Err)
  CALL cmfe_Field_NumberOfComponentsSet(DependentFieldSolid,CMFE_FIELD_V_VARIABLE_TYPE,FieldDependentFluidNumberOfComponents,Err)
  CALL cmfe_Field_NumberOfComponentsSet(DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE, &
    & FieldDependentFluidNumberOfComponents,Err)
  !
  CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,1,SolidDisplMeshComponentNumber,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,2,SolidDisplMeshComponentNumber,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,3,SolidDisplMeshComponentNumber,Err)
  CALL cmfe_Field_ComponentInterpolationSet(DependentFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,4, &
    & CMFE_FIELD_NODE_BASED_INTERPOLATION, &
    & Err)
!   CALL cmfe_Field_ComponentInterpolationSet(DependentFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,4,CMFE_FIELD_ELEMENT_BASED_INTERPOLATION,Err)
!   CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,4,SolidMeshComponenetNumber,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,4,SolidLagrMultMeshComponentNumber,Err)
  !
  CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,1, &
    & SolidDisplMeshComponentNumber, &
    & Err)
  CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,2, &
    & SolidDisplMeshComponentNumber, &
    & Err)
  CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,3, &
    & SolidDisplMeshComponentNumber, &
    & Err)
  CALL cmfe_Field_ComponentInterpolationSet(DependentFieldSolid,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,4, &
    & CMFE_FIELD_NODE_BASED_INTERPOLATION,Err)
!   CALL cmfe_Field_ComponentInterpolationSet(DependentFieldSolid,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,4, &
!     & CMFE_FIELD_ELEMENT_BASED_INTERPOLATION,Err)
!   CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,4,SolidMeshComponenetNumber,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,4, &
    & SolidLagrMultMeshComponentNumber, &
    & Err)

  !For this equation type, MESH_COMPONENT_NUMBER_PRESSURE is actually the mass increase component as the pressure is taken from the solid equations
  CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_V_VARIABLE_TYPE,1,DarcyVelMeshComponentNumber,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_V_VARIABLE_TYPE,2,DarcyVelMeshComponentNumber,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_V_VARIABLE_TYPE,3,DarcyVelMeshComponentNumber,Err)
!   CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_V_VARIABLE_TYPE,4,MESH_COMPONENT_NUMBER_PRESSURE,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_V_VARIABLE_TYPE,4, &
    & DarcyMassIncreaseMeshComponentNumber, &
    & Err)
  CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,1,DarcyVelMeshComponentNumber, &
    & Err)
  CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,2,DarcyVelMeshComponentNumber, &
    & Err)
  CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,3,DarcyVelMeshComponentNumber, &
    & Err)
!   CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,4,MESH_COMPONENT_NUMBER_PRESSURE,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,4, &
    & DarcyMassIncreaseMeshComponentNumber,Err)

  CALL cmfe_Field_CreateFinish(DependentFieldSolid,Err)
  !
  CALL cmfe_EquationsSet_DependentCreateStart(EquationsSetSolid,FieldDependentSolidUserNumber,DependentFieldSolid,Err)
  CALL cmfe_EquationsSet_DependentCreateFinish(EquationsSetSolid,Err)

  ! end Solid
  !--------------------------------------------------------------------------------------------------------------------------------


  !Create the equations set dependent field variables for ALE Darcy
  CALL cmfe_EquationsSet_DependentCreateStart(EquationsSetDarcy,FieldDependentSolidUserNumber, & ! ??? UserNumber ???
    & DependentFieldSolid,Err)
  CALL cmfe_EquationsSet_DependentCreateFinish(EquationsSetDarcy,Err)

  !Initialise dependent field (velocity components,mass increase)
  DO COMPONENT_NUMBER=1,NUMBER_OF_DIMENSIONS+1
    CALL cmfe_Field_ComponentValuesInitialise(DependentFieldSolid,CMFE_FIELD_V_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE, &
      & COMPONENT_NUMBER,INITIAL_FIELD_DARCY(COMPONENT_NUMBER),Err)
  ENDDO

  !
  !================================================================================================================================
  !

  !INDEPENDENT FIELD Darcy for storing BC flags

  CALL cmfe_Field_Initialise(IndependentFieldDarcy,Err)
  CALL cmfe_EquationsSet_IndependentCreateStart(EquationsSetDarcy,IndependentFieldDarcyUserNumber, &
    & IndependentFieldDarcy,Err)

  CALL cmfe_Field_ComponentMeshComponentSet(IndependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,1,DarcyVelMeshComponentNumber,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(IndependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,2,DarcyVelMeshComponentNumber,Err)
  CALL cmfe_Field_ComponentMeshComponentSet(IndependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,3,DarcyVelMeshComponentNumber,Err)
!   CALL cmfe_Field_ComponentMeshComponentSet(IndependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,4,DarcyMassIncreaseMeshComponentNumber,Err)

  CALL cmfe_EquationsSet_IndependentCreateFinish(EquationsSetDarcy,Err)

  CALL cmfe_Field_ComponentValuesInitialise(IndependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,1, &
    & 0.0_CMISSRP,Err)
  CALL cmfe_Field_ComponentValuesInitialise(IndependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,2, &
    & 0.0_CMISSRP,Err)
  CALL cmfe_Field_ComponentValuesInitialise(IndependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,3, &
    & 0.0_CMISSRP,Err)

  !
  !================================================================================================================================


  !
  !================================================================================================================================
  !

call READ_FIELD('input/pigheart-material',MaterialsFieldUserNumberDarcy,Region,GeometricField,MaterialsFieldDarcy)
CALL cmfe_EquationsSet_MaterialsCreateStart(EquationsSetDarcy,MaterialsFieldUserNumberDarcy,MaterialsFieldDarcy,Err)
CALL cmfe_EquationsSet_MaterialsCreateFinish(EquationsSetDarcy,Err)
!   !MATERIALS FIELDS
! 
!   !Create the equations set materials field variables for ALE Darcy
!   CALL cmfe_Field_Initialise(MaterialsFieldDarcy,Err)
!   CALL cmfe_EquationsSet_MaterialsCreateStart(EquationsSetDarcy,MaterialsFieldUserNumberDarcy, &
!     & MaterialsFieldDarcy,Err)
!   !Finish the equations set materials field variables
!   CALL cmfe_EquationsSet_MaterialsCreateFinish(EquationsSetDarcy,Err)
!   CALL cmfe_Field_ComponentValuesInitialise(MaterialsFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE, &
!     & MaterialsFieldUserNumberDarcyPorosity,POROSITY_PARAM_DARCY,Err)
!   CALL cmfe_Field_ComponentValuesInitialise(MaterialsFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE, &
!     & MaterialsFieldUserNumberDarcyPermOverVis,PERM_OVER_VIS_PARAM_DARCY,Err)

  !
  !================================================================================================================================
  !

  !EQUATIONS SET EQUATIONS

  !Darcy
  CALL cmfe_Equations_Initialise(EquationsDarcy,Err)
  CALL cmfe_EquationsSet_EquationsCreateStart(EquationsSetDarcy,EquationsDarcy,Err)
  CALL cmfe_Equations_SparsityTypeSet(EquationsDarcy,CMFE_EQUATIONS_SPARSE_MATRICES,Err)
  CALL cmfe_Equations_OutputTypeSet(EquationsDarcy,EQUATIONS_DARCY_OUTPUT,Err)
  CALL cmfe_EquationsSet_EquationsCreateFinish(EquationsSetDarcy,Err)

  !Solid
  CALL cmfe_Equations_Initialise(EquationsSolid,Err)
  CALL cmfe_EquationsSet_EquationsCreateStart(EquationsSetSolid,EquationsSolid,Err)
  CALL cmfe_Equations_SparsityTypeSet(EquationsSolid,CMFE_EQUATIONS_SPARSE_MATRICES,Err)
  CALL cmfe_Equations_OutputTypeSet(EquationsSolid,CMFE_EQUATIONS_NO_OUTPUT,Err)
  CALL cmfe_EquationsSet_EquationsCreateFinish(EquationsSetSolid,Err)

  !
  !================================================================================================================================
  !

  !--------------------------------------------------------------------------------------------------------------------------------
  ! Solid

  !Initialise dependent field from undeformed geometry and displacement bcs and set hydrostatic pressure
  CALL cmfe_Field_ParametersToFieldParametersComponentCopy(GeometricFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE, &
    & CMFE_FIELD_VALUES_SET_TYPE, &
    & 1,DependentFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,1,Err)
  CALL cmfe_Field_ParametersToFieldParametersComponentCopy(GeometricFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE, &
    & CMFE_FIELD_VALUES_SET_TYPE, &
    & 2,DependentFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,2,Err)
  CALL cmfe_Field_ParametersToFieldParametersComponentCopy(GeometricFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE, &
    & CMFE_FIELD_VALUES_SET_TYPE, &
    & 3,DependentFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,3,Err)
  CALL cmfe_Field_ComponentValuesInitialise(DependentFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,4, &
    & 0.0_CMISSRP, &
    & Err)

  ! end Solid
  !--------------------------------------------------------------------------------------------------------------------------------

  !
  !================================================================================================================================
  !

  !PROBLEMS

  CALL cmfe_Problem_Initialise(Problem,Err)
  CALL cmfe_ControlLoop_Initialise(ControlLoop,Err)
  CALL cmfe_Problem_CreateStart(ProblemUserNumber,[CMFE_PROBLEM_MULTI_PHYSICS_CLASS,CMFE_PROBLEM_FINITE_ELASTICITY_DARCY_TYPE, &
    & CMFE_PROBLEM_QUASISTATIC_ELASTICITY_TRANSIENT_DARCY_SUBTYPE],Problem,Err)
  CALL cmfe_Problem_CreateFinish(Problem,Err)

  CALL cmfe_Problem_ControlLoopCreateStart(Problem,Err)
  CALL cmfe_Problem_ControlLoopGet(Problem,CMFE_CONTROL_LOOP_NODE,ControlLoop,Err)
!   CALL cmfe_ControlLoop_MaximumIterationsSet(ControlLoop,2,Err)
  CALL cmfe_ControlLoop_TimesSet(ControlLoop,DYNAMIC_SOLVER_DARCY_START_TIME,DYNAMIC_SOLVER_DARCY_STOP_TIME, &
    & DYNAMIC_SOLVER_DARCY_TIME_INCREMENT,Err)
  CALL cmfe_ControlLoop_TimeOutputSet(ControlLoop,DYNAMIC_SOLVER_DARCY_OUTPUT_FREQUENCY,Err)
!   CALL cmfe_ControlLoop_OutputTypeSet(ControlLoop,CMFE_CONTROL_LOOP_PROGRESS_OUTPUT,Err)
  CALL cmfe_Problem_ControlLoopCreateFinish(Problem,Err)

  !
  !================================================================================================================================
  !

  !SOLVERS

  CALL cmfe_Solver_Initialise(SolverSolid,Err)
  CALL cmfe_Solver_Initialise(DynamicSolverDarcy,Err)
  CALL cmfe_Solver_Initialise(LinearSolverDarcy,Err)

  CALL cmfe_Problem_SolversCreateStart(Problem,Err)

  ! Solid
  CALL cmfe_Problem_SolverGet(Problem,[ControlLoopSubiterationNumber,ControlLoopSolidNumber,CMFE_CONTROL_LOOP_NODE], &
    & SolverSolidIndex,SolverSolid,Err)
  CALL cmfe_Solver_OutputTypeSet(SolverSolid,CMFE_SOLVER_PROGRESS_OUTPUT,Err)
!   CALL cmfe_Solver_NewtonJacobianCalculationTypeSet(SolverSolid,CMFE_SOLVER_NEWTON_JACOBIAN_FD_CALCULATED,Err)
  CALL cmfe_Solver_NewtonJacobianCalculationTypeSet(SolverSolid,CMFE_SOLVER_NEWTON_JACOBIAN_EQUATIONS_CALCULATED,Err)

  CALL cmfe_Solver_NewtonAbsoluteToleranceSet(SolverSolid,ABSOLUTE_TOLERANCE,Err)
  CALL cmfe_Solver_NewtonRelativeToleranceSet(SolverSolid,RELATIVE_TOLERANCE,Err)
  CALL cmfe_Solver_NewtonMaximumIterationsSet(SolverSolid,MAXIMUM_ITERATIONS,Err)

!   CALL cmfe_SolverNonLinearTypeSet(SolverSolid,CMFE_SOLVER_NONLINEAR_NEWTON,Err)
!   CALL cmfe_Solver_LibraryTypeSet(SolverSolid,CMFE_SOLVER_PETSC_LIBRARY,Err)

  CALL cmfe_Solver_NewtonLinearSolverGet(SolverSolid,LinearSolverSolid,Err)
  CALL cmfe_Solver_LinearTypeSet(LinearSolverSolid,CMFE_SOLVER_LINEAR_DIRECT_SOLVE_TYPE,Err)


  !Darcy
  CALL cmfe_Problem_SolverGet(Problem,[ControlLoopSubiterationNumber,ControlLoopFluidNumber,CMFE_CONTROL_LOOP_NODE], &
    & SolverDarcyIndex,DynamicSolverDarcy,Err)
  CALL cmfe_Solver_OutputTypeSet(DynamicSolverDarcy,DYNAMIC_SOLVER_DARCY_OUTPUT_TYPE,Err)
  CALL cmfe_Solver_DynamicThetaSet(DynamicSolverDarcy,DYNAMIC_SOLVER_DARCY_THETA,Err)
!   CALL cmfe_SolverDynamicDynamicSet(DynamicSolverDarcy,.TRUE.,Err)
  CALL cmfe_Solver_DynamicLinearSolverGet(DynamicSolverDarcy,LinearSolverDarcy,Err)
  IF(LINEAR_SOLVER_DARCY_DIRECT_FLAG) THEN
    CALL cmfe_Solver_LinearTypeSet(LinearSolverDarcy,CMFE_SOLVER_LINEAR_DIRECT_SOLVE_TYPE,Err)
    CALL cmfe_Solver_LibraryTypeSet(LinearSolverDarcy,CMFE_SOLVER_MUMPS_LIBRARY,Err)
  ELSE
    CALL cmfe_Solver_LinearTypeSet(LinearSolverDarcy,CMFE_SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE,Err)
    CALL cmfe_Solver_LinearIterativeMaximumIterationsSet(LinearSolverDarcy,MAXIMUM_ITERATIONS,Err)
    CALL cmfe_Solver_LinearIterativeDivergenceToleranceSet(LinearSolverDarcy,DIVERGENCE_TOLERANCE,Err)
    CALL cmfe_Solver_LinearIterativeRelativeToleranceSet(LinearSolverDarcy,RELATIVE_TOLERANCE,Err)
    CALL cmfe_Solver_LinearIterativeAbsoluteToleranceSet(LinearSolverDarcy,ABSOLUTE_TOLERANCE,Err)
    CALL cmfe_Solver_LinearIterativeGMRESRestartSet(LinearSolverDarcy,RESTART_VALUE,Err)
  ENDIF

  CALL cmfe_Problem_SolversCreateFinish(Problem,Err)

  !
  !================================================================================================================================
  !

  !SOLVER EQUATIONS

  CALL cmfe_Solver_Initialise(SolverSolid,Err)
  CALL cmfe_Solver_Initialise(LinearSolverDarcy,Err)

  CALL cmfe_SolverEquations_Initialise(SolverEquationsSolid,Err)
  CALL cmfe_SolverEquations_Initialise(SolverEquationsDarcy,Err)

  CALL cmfe_Problem_SolverEquationsCreateStart(Problem,Err)
  !
  !Get the finite elasticity solver equations
  CALL cmfe_Problem_SolverGet(Problem,[ControlLoopSubiterationNumber,ControlLoopSolidNumber,CMFE_CONTROL_LOOP_NODE], &
    & SolverSolidIndex,SolverSolid,Err)
  CALL cmfe_Solver_SolverEquationsGet(SolverSolid,SolverEquationsSolid,Err)
  CALL cmfe_SolverEquations_SparsityTypeSet(SolverEquationsSolid,CMFE_SOLVER_SPARSE_MATRICES,Err)
  CALL cmfe_SolverEquations_EquationsSetAdd(SolverEquationsSolid,EquationsSetSolid,EquationsSetIndex,Err)
  !
  !Get the Darcy solver equations
  CALL cmfe_Problem_SolverGet(Problem,[ControlLoopSubiterationNumber,ControlLoopFluidNumber,CMFE_CONTROL_LOOP_NODE], &
    & SolverDarcyIndex,LinearSolverDarcy,Err)
  CALL cmfe_Solver_SolverEquationsGet(LinearSolverDarcy,SolverEquationsDarcy,Err)
  CALL cmfe_SolverEquations_SparsityTypeSet(SolverEquationsDarcy,CMFE_SOLVER_SPARSE_MATRICES,Err)
  CALL cmfe_SolverEquations_EquationsSetAdd(SolverEquationsDarcy,EquationsSetDarcy,EquationsSetIndex,Err)
  !
  CALL cmfe_Problem_SolverEquationsCreateFinish(Problem,Err)

  !------------------------------------
  ! Grab surfaces to assign boundary conditions

  CALL READ_SURFACE('input/surface-lin-inner',surface_lin_inner)
  CALL READ_SURFACE('input/surface-lin-outer',surface_lin_outer)
  CALL READ_SURFACE('input/surface-lin-base',surface_lin_base)
  CALL READ_SURFACE('input/surface-quad-inner',surface_quad_inner)
  CALL READ_SURFACE('input/surface-quad-outer',surface_quad_outer)
  CALL READ_SURFACE('input/surface-quad-base',surface_quad_base)

  !------------------------------------
  ! ASSIGN BOUNDARY CONDITIONS - SOLID (absolute nodal parameters)
  !Solid is computed in absolute position, rather than displacement. Thus BCs for absolute position
  CALL cmfe_BoundaryConditions_Initialise(BoundaryConditionsSolid,Err)
  CALL cmfe_SolverEquations_BoundaryConditionsCreateStart(SolverEquationsSolid,BoundaryConditionsSolid,Err)

  write(*,*)'surface_quad_base = ',surface_quad_base

  INNER_PRESSURE = 0.01_CMISSRP
  OUTER_PRESSURE = 0.0_CMISSRP

  ! ASSIGN BOUNDARY CONDITIONS
  !Fix base of the ellipsoid in z direction
  DO NN=1,SIZE(surface_quad_base,1)
    NODE=surface_quad_base(NN)
    CALL cmfe_Decomposition_NodeDomainGet(Decomposition,NODE,1,NodeDomain,Err)
    IF(NodeDomain==ComputationalNodeNumber) THEN
      CALL cmfe_Field_ParameterSetGetNode(GeometricFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,1,1,NODE,3, &
        & ZCoord,Err)
      CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsSolid,DependentFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,1,1,NODE,3, &
        & CMFE_BOUNDARY_CONDITION_FIXED,ZCoord,Err)
    ENDIF
  ENDDO

!   !Apply inner surface pressure
!   !NOTE: Surface pressure goes into pressure_values_set_type of the DELUDELN type
!   DO NN=1,SIZE(surface_quad_inner,1)
!     NODE=surface_quad_inner(NN)
!     CALL cmfe_Decomposition_NodeDomainGet(Decomposition,NODE,1,NodeDomain,Err)
!     IF(NodeDomain==ComputationalNodeNumber) THEN
!       COMPONENT_NUMBER = 3  ! Does it matter which number ??? It used to be linked to the normal ... Check this !!!
!       CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsSolid,DependentFieldSolid,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,1,NODE,COMPONENT_NUMBER, &
!         & CMFE_BOUNDARY_CONDITION_PRESSURE,INNER_PRESSURE,Err)
!     ENDIF
!   ENDDO
!
!   !Apply outer surface pressure
!   DO NN=1,SIZE(surface_quad_outer,1)
!     NODE=surface_quad_outer(NN)
!     CALL cmfe_Decomposition_NodeDomainGet(Decomposition,NODE,1,NodeDomain,Err)
!     IF(NodeDomain==ComputationalNodeNumber) THEN
!       COMPONENT_NUMBER = 3  ! Does it matter which number ??? It used to be linked to the normal ... Check this !!!
!       CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsSolid,DependentFieldSolid,CMFE_FIELD_DELUDELN_VARIABLE_TYPE,1,NODE,COMPONENT_NUMBER, &
!         & CMFE_BOUNDARY_CONDITION_PRESSURE,OUTER_PRESSURE,Err)
!     ENDIF
!   ENDDO

  !Fix more nodes at the base to stop free body motion: 600 in x, 584 in y
  X_FIXED=.FALSE.
  Y_FIXED=.FALSE.
  DO NN=1,SIZE(surface_quad_base,1)
    NODE=surface_quad_base(NN)
    CALL cmfe_Decomposition_NodeDomainGet(Decomposition,NODE,1,NodeDomain,Err)
    IF(NodeDomain==ComputationalNodeNumber) THEN
      CALL cmfe_Field_ParameterSetGetNode(GeometricFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,1,1,NODE,1, &
        & XCoord,Err)
      CALL cmfe_Field_ParameterSetGetNode(GeometricFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,1,1,NODE,2, &
        & YCoord,Err)
!       IF(ABS(XCoord)<1.0E-6_CMISSRP) THEN
      IF(NODE==600) THEN
        CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsSolid,DependentFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,1,1,NODE,1, &
          & CMFE_BOUNDARY_CONDITION_FIXED,XCoord,Err)
        WRITE(*,*) "FIXING NODE",NODE,"IN X DIRECTION"
        X_FIXED=.TRUE.
      ENDIF
!       IF(ABS(YCoord)<1.0E-6_CMISSRP) THEN
      IF(NODE==584) THEN
        CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsSolid,DependentFieldSolid,CMFE_FIELD_U_VARIABLE_TYPE,1,1,NODE,2, &
          & CMFE_BOUNDARY_CONDITION_FIXED,YCoord,Err)
        WRITE(*,*) "FIXING NODE",NODE,"IN Y DIRECTION"
        Y_FIXED=.TRUE.
    ENDIF
    ENDIF
  ENDDO
!   CALL MPI_REDUCE(X_FIXED,X_OKAY,1,MPI_LOGICAL,MPI_LOR,0,MPI_COMM_WORLD,MPI_IERROR)
!   CALL MPI_REDUCE(Y_FIXED,Y_OKAY,1,MPI_LOGICAL,MPI_LOR,0,MPI_COMM_WORLD,MPI_IERROR)
  IF(ComputationalNodeNumber==0) THEN
!     IF(.NOT.(X_OKAY.AND.Y_OKAY)) THEN
    IF(.NOT.(X_FIXED.AND.Y_FIXED)) THEN
      WRITE(*,*) "Free body motion could not be prevented!"
      CALL cmfe_Finalise(Err)
    STOP
    ENDIF
  ENDIF

  CALL cmfe_SolverEquations_BoundaryConditionsCreateFinish(SolverEquationsSolid,Err)

  !
  !================================================================================================================================
  !

  !BCs Darcy
  CALL cmfe_BoundaryConditions_Initialise(BoundaryConditionsDarcy,Err)
  CALL cmfe_SolverEquations_BoundaryConditionsCreateStart(SolverEquationsDarcy,BoundaryConditionsDarcy,Err)

    !In 'generated_mesh_routines.f90/GENERATED_MESH_ELLIPSOID_SURFACE_GET' there is a bug:
    !  BASIS=>ELLIPSOID_MESH%BASES(MESH_COMPONENT)%PTR does not account for the fact that:
    !  in 'generated_mesh_routines.f90/GENERATED_MESH_ELLIPSOID_CREATE_FINISH' the following is done:
    !  CALL MESH_NUMBER_OF_COMPONENTS_SET(GENERATED_MESH%MESH,SIZE(ELLIPSOID_MESH%BASES)/2,ERR,ERROR,*999)
    !Temporary work around, until bug fix:


    !  I N N E R   S U R F A C E

    write(*,*)'surface_lin_inner = ',surface_lin_inner

    !Set all inner surface nodes impermeable
    !MIND: CMFE_FIELD_DELVDELN_VARIABLE_TYPE -> RHS invoked in DARCY_EQUATION_FINITE_ELEMENT_CALCULATE
    !      CMFE_BOUNDARY_CONDITION_IMPERMEABLE_WALL
    DO NN=1,SIZE(surface_lin_inner,1)
!       VALUE = 0.0_CMISSRP
!       COMPONENT_NUMBER = 1
!       CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,1,surface_lin_inner(NN), &
!         & COMPONENT_NUMBER,CMFE_BOUNDARY_CONDITION_IMPERMEABLE_WALL,VALUE,Err)
!       IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING INNER DARCY BC TO NODE", surface_lin_inner(NN)
!
!       VALUE = 0.0_CMISSRP
!       COMPONENT_NUMBER = 2
!       CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,1,surface_lin_inner(NN), &
!         & COMPONENT_NUMBER,CMFE_BOUNDARY_CONDITION_IMPERMEABLE_WALL,VALUE,Err)
!       IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING INNER DARCY BC TO NODE", surface_lin_inner(NN)
!
!       VALUE = 0.0_CMISSRP
!       COMPONENT_NUMBER = 3
!       CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,1,surface_lin_inner(NN), &
!         & COMPONENT_NUMBER,CMFE_BOUNDARY_CONDITION_IMPERMEABLE_WALL,VALUE,Err)
!       IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING INNER DARCY BC TO NODE", surface_lin_inner(NN)

!       VALUE = 1.0_CMISSRP
!       COMPONENT_NUMBER = ABS(InnerNormalXi)
!       CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,1,surface_lin_inner(NN), &
!         & COMPONENT_NUMBER,CMFE_BOUNDARY_CONDITION_IMPERMEABLE_WALL,VALUE,Err)
!       IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING INNER DARCY BC TO NODE", surface_lin_inner(NN)

      NODE_NUMBER = surface_lin_inner(NN)
      COMPONENT_NUMBER = 1
      VALUE = 1.0_CMISSRP
      CALL cmfe_Field_ParameterSetUpdateNode(IndependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,1, &
        & CMFE_NO_GLOBAL_DERIV,NODE_NUMBER,COMPONENT_NUMBER,VALUE,Err)
    ENDDO


    !  O U T E R   S U R F A C E

    write(*,*)'surface_lin_outer = ',surface_lin_outer

    !Set all outer surface nodes impermeable
    DO NN=1,SIZE(surface_lin_outer,1)
!       VALUE = 0.0_CMISSRP
!       COMPONENT_NUMBER = 1
!       CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,1,surface_lin_outer(NN), &
!         & COMPONENT_NUMBER,CMFE_BOUNDARY_CONDITION_IMPERMEABLE_WALL,VALUE,Err)
!       IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING OUTER DARCY BC TO NODE", surface_lin_outer(NN)
!
!       VALUE = 0.0_CMISSRP
!       COMPONENT_NUMBER = 2
!       CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,1,surface_lin_outer(NN), &
!         & COMPONENT_NUMBER,CMFE_BOUNDARY_CONDITION_IMPERMEABLE_WALL,VALUE,Err)
!       IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING OUTER DARCY BC TO NODE", surface_lin_outer(NN)
!
!       VALUE = 0.0_CMISSRP
!       COMPONENT_NUMBER = 3
!       CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,1,surface_lin_outer(NN), &
!         & COMPONENT_NUMBER,CMFE_BOUNDARY_CONDITION_IMPERMEABLE_WALL,VALUE,Err)
!       IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING OUTER DARCY BC TO NODE", surface_lin_outer(NN)

!       VALUE = 1.0_CMISSRP
!       COMPONENT_NUMBER = ABS(OuterNormalXi)
!       CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,1,surface_lin_outer(NN), &
!         & COMPONENT_NUMBER,CMFE_BOUNDARY_CONDITION_IMPERMEABLE_WALL,VALUE,Err)
!       IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING OUTER DARCY BC TO NODE", surface_lin_outer(NN)

      NODE_NUMBER = surface_lin_outer(NN)
      COMPONENT_NUMBER = 1
      VALUE = 1.0_CMISSRP
      CALL cmfe_Field_ParameterSetUpdateNode(IndependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,1, &
        & CMFE_NO_GLOBAL_DERIV,NODE_NUMBER,COMPONENT_NUMBER,VALUE,Err)
    ENDDO


    !  T O P   S U R F A C E

    write(*,*)'surface_lin_base = ',surface_lin_base

    !Set all top surface nodes to Darcy inflow BC
    DO NN=1,SIZE(surface_lin_base,1)
!       VALUE = +1.0_CMISSRP  ! Mind the sign !
      VALUE = 0.0_CMISSRP  ! Mind the sign !
      COMPONENT_NUMBER = 3
      CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldSolid,CMFE_FIELD_V_VARIABLE_TYPE,1,1, &
        & surface_lin_base(NN), &
        & COMPONENT_NUMBER,CMFE_BOUNDARY_CONDITION_FIXED,VALUE,Err)
      IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING TOP DARCY BC TO NODE", surface_lin_base(NN)
    ENDDO

    DO NN=1,SIZE(surface_lin_inner,1)
!       VALUE = 0.0_CMISSRP
!       COMPONENT_NUMBER = 1
!       CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,1,InnerSurfaceNodesDarcyVel(NN), &
!         & COMPONENT_NUMBER,CMFE_BOUNDARY_CONDITION_IMPERMEABLE_WALL,VALUE,Err)
!       IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING INNER DARCY BC TO NODE", InnerSurfaceNodesDarcyVel(NN)
!
!       VALUE = 0.0_CMISSRP
!       COMPONENT_NUMBER = 2
!       CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,1,InnerSurfaceNodesDarcyVel(NN), &
!         & COMPONENT_NUMBER,CMFE_BOUNDARY_CONDITION_IMPERMEABLE_WALL,VALUE,Err)
!       IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING INNER DARCY BC TO NODE", InnerSurfaceNodesDarcyVel(NN)
!
!       VALUE = 0.0_CMISSRP
!       COMPONENT_NUMBER = 3
!       CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,1,InnerSurfaceNodesDarcyVel(NN), &
!         & COMPONENT_NUMBER,CMFE_BOUNDARY_CONDITION_IMPERMEABLE_WALL,VALUE,Err)
!       IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING INNER DARCY BC TO NODE", InnerSurfaceNodesDarcyVel(NN)

!       VALUE = 1.0_CMISSRP
!       COMPONENT_NUMBER = ABS(InnerNormalXi)
!       CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,1,InnerSurfaceNodesDarcyVel(NN), &
!         & COMPONENT_NUMBER,CMFE_BOUNDARY_CONDITION_IMPERMEABLE_WALL,VALUE,Err)
!       IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING INNER DARCY BC TO NODE", InnerSurfaceNodesDarcyVel(NN)

      NODE_NUMBER = surface_lin_inner(NN)
      !COMPONENT_NUMBER = ABS(InnerNormalXi)
      COMPONENT_NUMBER=1_CMISSIntg
      VALUE = 1.0_CMISSRP
      CALL cmfe_Field_ParameterSetUpdateNode(IndependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,1, &
        & CMFE_NO_GLOBAL_DERIV,NODE_NUMBER,COMPONENT_NUMBER,VALUE,Err)

    ENDDO
    DO NN=1,SIZE(surface_lin_outer,1)
!       VALUE = 0.0_CMISSRP
!       COMPONENT_NUMBER = 1
!       CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,1,OuterSurfaceNodesDarcyVel(NN), &
!         & COMPONENT_NUMBER,CMFE_BOUNDARY_CONDITION_IMPERMEABLE_WALL,VALUE,Err)
!       IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING OUTER DARCY BC TO NODE", OuterSurfaceNodesDarcyVel(NN)
!
!       VALUE = 0.0_CMISSRP
!       COMPONENT_NUMBER = 2
!       CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,1,OuterSurfaceNodesDarcyVel(NN), &
!         & COMPONENT_NUMBER,CMFE_BOUNDARY_CONDITION_IMPERMEABLE_WALL,VALUE,Err)
!       IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING OUTER DARCY BC TO NODE", OuterSurfaceNodesDarcyVel(NN)
!
!       VALUE = 0.0_CMISSRP
!       COMPONENT_NUMBER = 3
!       CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,1,OuterSurfaceNodesDarcyVel(NN), &
!         & COMPONENT_NUMBER,CMFE_BOUNDARY_CONDITION_IMPERMEABLE_WALL,VALUE,Err)
!       IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING OUTER DARCY BC TO NODE", OuterSurfaceNodesDarcyVel(NN)

!       VALUE = 1.0_CMISSRP
!       COMPONENT_NUMBER = ABS(OuterNormalXi)
!       CALL cmfe_BoundaryConditions_SetNode(BoundaryConditionsDarcy,DependentFieldSolid,CMFE_FIELD_DELVDELN_VARIABLE_TYPE,1,OuterSurfaceNodesDarcyVel(NN), &
!         & COMPONENT_NUMBER,CMFE_BOUNDARY_CONDITION_IMPERMEABLE_WALL,VALUE,Err)
!       IF(Err/=0) WRITE(*,*) "ERROR WHILE ASSIGNING OUTER DARCY BC TO NODE", OuterSurfaceNodesDarcyVel(NN)

      NODE_NUMBER = surface_lin_outer(NN)
      !COMPONENT_NUMBER = ABS(OuterNormalXi)
      COMPONENT_NUMBER=1_CMISSIntg
      VALUE = 1.0_CMISSRP
      CALL cmfe_Field_ParameterSetUpdateNode(IndependentFieldDarcy,CMFE_FIELD_U_VARIABLE_TYPE,CMFE_FIELD_VALUES_SET_TYPE,1, &
        & CMFE_NO_GLOBAL_DERIV,NODE_NUMBER,COMPONENT_NUMBER,VALUE,Err)
    ENDDO



  CALL cmfe_SolverEquations_BoundaryConditionsCreateFinish(SolverEquationsDarcy,Err)

  !
  !================================================================================================================================
  !

  !RUN SOLVERS

  !Turn of PETSc error handling
  !CALL PETSC_ERRORHANDLING_SET_ON(ERR,ERROR,*999)

  !Solve the problem
  WRITE(*,'(A)') "Solving problem..."
  CALL cmfe_Problem_Solve(Problem,Err)
  WRITE(*,'(A)') "Problem solved!"


  !
  !================================================================================================================================
  !

  !OUTPUT

  EXPORT_FIELD_IO=.FALSE.
  IF(EXPORT_FIELD_IO) THEN
    WRITE(*,'(A)') "Exporting fields..."
    CALL cmfe_Fields_Initialise(Fields,Err)
    CALL cmfe_Fields_Create(Region,Fields,Err)
    CALL cmfe_Fields_NodesExport(Fields,"FiniteElasticityDarcy","FORTRAN",Err)
    CALL cmfe_Fields_ElementsExport(Fields,"FiniteElasticityDarcy","FORTRAN",Err)
    CALL cmfe_Fields_Finalise(Fields,Err)
    WRITE(*,'(A)') "Field exported!"
  ENDIF


  !Finialise CMISS
!   CALL cmfe_Finalise(Err)

  WRITE(*,'(A)') "Program successfully completed."

  STOP

END PROGRAM FINITEELASTICITYDARCYIOEXAMPLE
