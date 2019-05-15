//
//  MasterViewController.m
//  Nabto5 iOS Demo
//
//  Created by Ulrik Gammelby on 08/05/2019.
//  Copyright © 2019 Nabto ApS. All rights reserved.
//

#import <nabto/nabto_client.h>
#import "MasterViewController.h"
#import "DetailViewController.h"

@interface MasterViewController ()

@property NSMutableArray *objects;
@property NabtoClientConnection* connection;
@property NabtoClientContext* context;
@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(handleAdd:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
}


- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

static void connectCallback(NabtoClientFuture *future, void *data)
{
    MasterViewController* self = (__bridge MasterViewController*)data;
    NabtoClientError ec = nabto_client_future_error_code(future);
    [self insertNewObject:[self stringWithNabtoError:@"Connect completed"
                                               error:ec]];
    if (ec == NABTO_CLIENT_OK) {
        [self nabtoStreamOpen];
    } else {
        // crash ved ec = NABTO_CLIENT_API_UNKNOWN_ERROR
        nabto_client_context_free(self.context);
        nabto_client_connection_free(self.connection);
    }
}

- (void)nabtoStreamOpen {
    NabtoClientStream* stream = nabto_client_stream_new(self.connection);
}

- (void)nabtoConnect {
    const char* clientPrivateKey =
            "-----BEGIN EC PARAMETERS-----\r\n"
            "BggqhkjOPQMBBw==\r\n"
            "-----END EC PARAMETERS-----\r\n"
            "-----BEGIN EC PRIVATE KEY-----\r\n"
            "MHcCAQEEIBnZr32pwf7eH5vLqDD5hgzR3EzoEJVZ0tT4QqjakFrGoAoGCCqGSM49\r\n"
            "AwEHoUQDQgAEPexGIS7sjA6BmOKbvCsu3/I/qxjY2CTE5RANbiaw7xWwHEcexYYR\r\n"
            "nM7sgVTdDTc2zrOYpqAA0a2k3UnUJloxFg==\r\n"
            "-----END EC PRIVATE KEY-----\r\n";

    const char* clientPublicKey =
            "-----BEGIN CERTIFICATE-----\r\n"
            "MIIBcjCCARmgAwIBAgIUYFak71fL+KboKr4jtogCMTnwu8EwCgYIKoZIzj0EAwIw\r\n"
            "DzENMAsGA1UEAwwEdGVzdDAeFw0xOTAxMjIxMjI3NDBaFw00OTAxMTQxMjI3NDBa\r\n"
            "MA8xDTALBgNVBAMMBHRlc3QwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAAQ97EYh\r\n"
            "LuyMDoGY4pu8Ky7f8j+rGNjYJMTlEA1uJrDvFbAcRx7FhhGczuyBVN0NNzbOs5im\r\n"
            "oADRraTdSdQmWjEWo1MwUTAdBgNVHQ4EFgQU75BPhlLAkabkX3iWSygFLlfsiA8w\r\n"
            "HwYDVR0jBBgwFoAU75BPhlLAkabkX3iWSygFLlfsiA8wDwYDVR0TAQH/BAUwAwEB\r\n"
            "/zAKBggqhkjOPQQDAgNHADBEAiAoOa8sH/pvWujJugT+QZpHymoQTEIzvRpw1kCG\r\n"
            "Op3TPwIgQ0oZ/vd0TjSz0xzQTtu14nsrOBtmBtq8RAtf5BnI4Xw=\r\n"
            "-----END CERTIFICATE-----\r\n";

    const char* serverUrl = "https://pr-wrukmj9.clients.dev.nabto.net";
    const char* productId = "pr-wrukmj9j";
    const char* deviceId = "de-ffivbgce";
    const char* serverKey = "sk-10945a44533540db82eb56fb62f5b3c5";

    [self insertNewObject:[NSString stringWithFormat:@"Connecting to %s::%s...", productId, deviceId]];

    // TODO... disable connect button until complete or manage multiple concurrent contexts/connections
    self.context = nabto_client_context_new();
    self.connection = nabto_client_connection_new(self.context);
    NabtoClientError ec;

    if ((ec = nabto_client_connection_set_server_url(self.connection, serverUrl)) != NABTO_CLIENT_OK) {
        [self insertNewObject:[self stringWithNabtoError:@"Error" error:ec]];
    }

    if ((ec = nabto_client_connection_set_product_id(self.connection, productId)) != NABTO_CLIENT_OK) {
        [self insertNewObject:[self stringWithNabtoError:@"Error" error:ec]];
    }

    if ((ec = nabto_client_connection_set_device_id(self.connection, deviceId)) != NABTO_CLIENT_OK) {
        [self insertNewObject:[self stringWithNabtoError:@"Error" error:ec]];
    }

    if ((ec = nabto_client_connection_set_public_key(self.connection, clientPublicKey)) != NABTO_CLIENT_OK) {
        [self insertNewObject:[self stringWithNabtoError:@"Error" error:ec]];
    }

    if ((ec = nabto_client_connection_set_private_key(self.connection, clientPrivateKey)) != NABTO_CLIENT_OK) {
        [self insertNewObject:[self stringWithNabtoError:@"Error" error:ec]];
    }

    if ((ec = nabto_client_connection_set_server_api_key(self.connection, serverKey)) != NABTO_CLIENT_OK) {
        [self insertNewObject:[self stringWithNabtoError:@"Error" error:ec]];
    }

    NabtoClientFuture* connectFuture = nabto_client_connection_connect(self.connection);
    nabto_client_future_set_callback(connectFuture, connectCallback, (__bridge void *) self);
}

- (NSString *)stringWithNabtoError:(NSString*)message error:(NabtoClientError)ec {
    const char* status = ec == NABTO_CLIENT_OK ? "OK" : nabto_client_error_get_message(ec);
    return [NSString stringWithFormat:@"%@ - Status %d: %s", message, ec, status];
}

- (void)handleAdd:(id)sender {
    [self nabtoConnect];
}

- (void)insertNewObject:(NSObject *)obj {
    if (!self.objects) {
        self.objects = [[NSMutableArray alloc] init];
    }
    [self.objects insertObject:obj atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSObject *object = self.objects[indexPath.row];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:object];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    NSObject *object = self.objects[indexPath.row];
    cell.textLabel.text = [object description];
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}


@end
