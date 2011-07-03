//
//  Ecosystem.m
//  GenSoup
//
//  Created by Borja Arias Drake on 22/05/2011.
//  Copyright 2011 Unboxed Consulting. All rights reserved.
//

#import "Ecosystem.h"

@interface Ecosystem(private)
- (int) numberOfNeighbours:(Matrix2DCoordenate*)position inSet:(NSMutableSet*)cellSet;
- (BOOL)areNeighboursCoordinate:(Matrix2DCoordenate*)coor1 withCoordinate:(Matrix2DCoordenate*)coor2;
- (void) createNewAliveForNextGeneration;
- (void) updateCurrentCellStateForNextGeneration;
- (void) eliminateEmptyCoordinatesForNextGeneration;
- (void) findEmptyPostionsWithThreeAliveForNextGeneration;
- (void) swapCurrentAndNextGenerationSets;
- (BOOL) rowValid:(int) row;
- (BOOL) colValid:(int) col;
- (void) calculateEmptyWith3ForAliveSet:(NSMutableSet*)aliveSet andEmptyWith3Set:(NSMutableSet*)emptySet;
@end



@implementation Ecosystem

@synthesize aliveCells;

#pragma mark - Init Methods

- (id) initWithRows:(int)theRows andColumns:(int)theColumns andInitialPopulation:(NSSet*)population
{
    /***********************************************************************************************/
    /* Designated init method.                                                                     */
	/***********************************************************************************************/
    if((self = [super init]))
    {
        int numberOfCellInMatrix = theRows * theColumns;
        
        if([population count] > numberOfCellInMatrix)
            @throw @"The given population has more elements than the matrix defined by the given rows and columns.";
            
        //[[self emptySurroundingCoordinatesForPopulation:(NSSet*)[self->aliveCells copy]] mutableCopy];
        self->aliveCells = [[NSMutableSet setWithSet:population] retain];
        self->emptyWith3Alive = [[NSMutableSet alloc] init];
        self->nextGenAliveCells = [[NSMutableSet alloc] init];
        self->nextGenEmptyWith3Alive = [[NSMutableSet alloc] init];
        self->rows = theRows;
        self->columns = theColumns;
        
        [self calculateEmptyWith3ForAliveSet:self->aliveCells andEmptyWith3Set:self->emptyWith3Alive];
    }
    
    return self;
}


- (id) init
{
    /***********************************************************************************************/
    /* init method.                                                                                */
	/***********************************************************************************************/
    @throw @"use initWithRows:andColumns:andInitialPopulation instead.";
}



#pragma mark - Algorithmic Methods

- (void) produceNextGeneration
{
    /***********************************************************************************************/
    /* Iterate through occuped cells and updates it.                                               */
	/***********************************************************************************************/
    [self createNewAliveForNextGeneration];
    [self updateCurrentCellStateForNextGeneration];
    [self eliminateEmptyCoordinatesForNextGeneration];
    [self findEmptyPostionsWithThreeAliveForNextGeneration];
    [self swapCurrentAndNextGenerationSets];
}


- (int) numberOfNeighbours:(Matrix2DCoordenate*)position inSet:(NSMutableSet*)cellSet
{
    /***********************************************************************************************/
    /* Given a cell, it returns the number of surrounding cells.                                   */
	/***********************************************************************************************/
    if(![self rowValid:position.row] || ![self colValid:position.column])
        @throw @"The given coordinate does not exist in the Ecosystem.";

    int numberOfNeighbours = 0;
    
    for (Cell* c in cellSet)
    {
        if (![c.coordinate isEqual:position])
        {
            if([self areNeighboursCoordinate:c.coordinate withCoordinate:position])
            {
                numberOfNeighbours++;
                if(numberOfNeighbours == 4)
                {
                    break;
                }
            }
        }
    }
    
    return numberOfNeighbours;    
}


- (BOOL)areNeighboursCoordinate:(Matrix2DCoordenate*)coor1 withCoordinate:(Matrix2DCoordenate*)coor2
{
    /***********************************************************************************************/
    /* Given 2 coordinates it returns true if they are neighbours.                                 */
	/***********************************************************************************************/
    BOOL result = YES;    
    int absRowDistance = abs(coor1.row - coor2.row);
    int absColDistance = abs(coor1.column - coor2.column);
    
    if ((absRowDistance > 1) || (absColDistance > 1))
    {
        result = NO;
    }
    
    return result;
}


- (void) createNewAliveForNextGeneration
{
    /***********************************************************************************************/
    /* We'll create a new cell for the next generation for each empty position with 3 surrounding  */
    /* cells.                                                                                      */
	/***********************************************************************************************/
    for (Matrix2DCoordenate* coor in self->emptyWith3Alive)
    {
        Matrix2DCoordenate* coorCopy = [coor copy];
        Cell* newCell = [[Cell alloc] initWithCoordinate:coorCopy andOrganismID:-1];
        
        [self->nextGenAliveCells addObject:newCell];
        
        [newCell release];
        [coorCopy release];
    }
}


- (void) updateCurrentCellStateForNextGeneration
{
    /***********************************************************************************************/
    /* For each current cell, we calculate the number of neighbours that it has (n)                */
    /*  if n<2 OR n>3 the cell dies, and goes to newEmptyCoordinatesWithThreeAlive                 */ 
    /*  else it survives and goes to newAliveCells                                                 */
	/***********************************************************************************************/
    for (Cell* cell in self->aliveCells)
    {
        int n = [self numberOfNeighbours:cell.coordinate inSet:self->aliveCells];
        Cell* cellCopy = [cell copy];        
        
        if((n<2) || (n>3))
        {            
            [self->nextGenEmptyWith3Alive addObject:cellCopy.coordinate];
        }
        else
        {
            [self->nextGenAliveCells addObject:cellCopy];
        }
        
        [cellCopy release];
    }
}


- (void) eliminateEmptyCoordinatesForNextGeneration
{
    /***********************************************************************************************/
    /* For each of the next generation emptyPositionsWith3AliveAround we calculate the neighbours. */
    /* if n is not 3, then, we remove from the array that keeps the positions with 3 alive around. */
	/***********************************************************************************************/
    NSMutableSet* auxSet = [[NSMutableSet alloc] init];
    
    for (Matrix2DCoordenate* coor in self->nextGenEmptyWith3Alive)
    {        
        int n = [self numberOfNeighbours:coor inSet:self->nextGenAliveCells];
        
        if (n != 3)
        {
            [auxSet addObject:coor];            
        }
    }
    
    for (Matrix2DCoordenate* coor in auxSet)
    {
        [self->nextGenEmptyWith3Alive removeObject:coor];
    }
    
    [auxSet release];
}


- (void) findEmptyPostionsWithThreeAliveForNextGeneration
{
    /***********************************************************************************************/
    /* For each cell in the new generation array (newAliceCells). we recalculate the number        */
    /* neighbours and check if they have 3 cells around.                                           */
	/***********************************************************************************************/
    for (Cell* cell in self->nextGenAliveCells)
    {
        int initialRow = cell.coordinate.row - 1;
        int initialCol = cell.coordinate.column - 1;
        int endRow = cell.coordinate.row + 1;
        int endCol = cell.coordinate.column + 1;
        
        for (int i=initialRow; i<=endRow; i++)
        {
            if ([self rowValid:i])
            {
                for (int j=initialCol; j<=endCol; j++)
                {
                    if ([self colValid:j])
                    {
                        Matrix2DCoordenate* coordinate = [[Matrix2DCoordenate alloc] initWithRow:i andColumn:j];
                        Cell* auxCell = [[Cell alloc] initWithCoordinate:coordinate andOrganismID:-1];

                        if(([self->nextGenAliveCells member:auxCell]==nil) && ([self->nextGenEmptyWith3Alive member:coordinate] == nil))
                        {                            
                            int n = [self numberOfNeighbours:coordinate inSet:self->nextGenAliveCells];
                            
                            if (n == 3)
                            {
                                [self->nextGenEmptyWith3Alive addObject:coordinate];
                            }                                                        
                        }
                        
                        [auxCell release];
                        [coordinate release];
                    }
                }
            }
        }
    }
}


- (void) swapCurrentAndNextGenerationSets
{
    /***********************************************************************************************/
    /* We trash the old generation, and make it be the new generation.                             */
	/***********************************************************************************************/
    // Release the old generation
    [self->aliveCells release];
    [self->emptyWith3Alive release];
    
    // Make the next generation be the current one
    self->aliveCells = [self->nextGenAliveCells retain];    
    self->emptyWith3Alive = [self->nextGenEmptyWith3Alive retain];
    
    // Reset the new generation structures
    [self->nextGenAliveCells release];
    self->nextGenAliveCells = [[NSMutableSet alloc] init];
    [self->nextGenEmptyWith3Alive release];
    self->nextGenEmptyWith3Alive = [[NSMutableSet alloc] init];
}


- (BOOL) rowValid:(int) row
{
    /***********************************************************************************************/
    /* Return if the row is valid in this ecosystem defined by rows and columns                    */
	/***********************************************************************************************/    
    return (row >= 0) && (row < self->rows);
}


- (BOOL) colValid:(int) col
{
    /***********************************************************************************************/
    /* Return if the column is valid in this ecosystem defined by rows and columns                 */
	/***********************************************************************************************/    
    return (col >= 0) && (col < self->columns);
}


- (void) printToConsole
{
    NSString* rowString = @"";
    
    for (int i=0; i<rows; i++)
    {        
        for (int j=0; j<columns; j++)
        {
            Matrix2DCoordenate* coor = [[Matrix2DCoordenate alloc] initWithRow:i andColumn:j];
            Cell* cell = [[Cell alloc] initWithCoordinate:coor andOrganismID:-1];
            
            if ([self->aliveCells member:cell] != nil)
            {
                rowString = [rowString stringByAppendingFormat:@"o "];
            }
            else
            {
                rowString = [rowString stringByAppendingFormat:@"- "];
            }
            
            [cell release];
            [coor release];
        }
        
        rowString = [rowString stringByAppendingFormat:@"\n"];
    }
    
    NSLog(@"%@", rowString);
}


- (void) calculateEmptyWith3ForAliveSet:(NSMutableSet*)aliveSet andEmptyWith3Set:(NSMutableSet*)emptySet
{
    for (Cell* cell in aliveSet)
    {
        int initialRow = cell.coordinate.row - 1;
        int initialCol = cell.coordinate.column - 1;
        int endRow = cell.coordinate.row + 1;
        int endCol = cell.coordinate.column + 1;
        
        for (int i=initialRow; i<=endRow; i++)
        {
            if ([self rowValid:i])
            {
                for (int j=initialCol; j<=endCol; j++)
                {
                    if ([self colValid:j])
                    {
                        Matrix2DCoordenate* coordinate = [[Matrix2DCoordenate alloc] initWithRow:i andColumn:j];
                        Cell* auxCell = [[Cell alloc] initWithCoordinate:coordinate andOrganismID:-1];
                        
                        if(([aliveSet member:auxCell]==nil) && ([emptySet member:coordinate] == nil))
                        {                            
                            int n = [self numberOfNeighbours:coordinate inSet:aliveSet];
                            
                            if (n == 3)
                            {
                                [emptySet addObject:coordinate];
                            }                                                        
                        }
                        
                        [auxCell release];
                        [coordinate release];
                    }
                }
            }
        }
    }    
}


#pragma mark - Memory Management

- (void) dealloc
{
    /***********************************************************************************************/
    /* Tidy-up.                                                                                    */
	/***********************************************************************************************/    
    [self->aliveCells release];
    self->aliveCells = nil;
    [self->emptyWith3Alive release];
    self->emptyWith3Alive = nil;

    [self->nextGenAliveCells release];
    self->nextGenAliveCells = nil;
    [self->nextGenEmptyWith3Alive release];
    self->nextGenEmptyWith3Alive = nil;

    [super dealloc];
}

@end
